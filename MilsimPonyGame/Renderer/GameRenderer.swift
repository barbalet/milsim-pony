import Foundation
import MetalKit
import QuartzCore
import simd

private struct RendererShadowFrame {
    let viewProjectionMatrix: simd_float4x4
    let strength: Float
    let normalBias: Float
    let texelSize: Float
}

private enum SceneMaterialTextureSemantic: Hashable {
    case albedo
    case normal
    case roughness
    case ambientOcclusion
}

private struct SceneMaterialTextureKey: Hashable {
    let reference: SceneTextureReference
    let semantic: SceneMaterialTextureSemantic
}

final class GameRenderer: NSObject, MTKViewDelegate {
    private static let maxFramesInFlight = 3
    private static let sceneColorPixelFormat: MTLPixelFormat = .rgba16Float

    private struct SessionOverlayUpdate {
        let snapshot: GameFrameSnapshot
        let drawableSize: CGSize
        let briefing: (summary: String, details: [String])
        let route: (summary: String, details: [String])
        let evasion: (summary: String, details: [String])
        let streaming: (summary: String, details: [String])
    }

    private struct SessionPerformanceUpdate {
        let milliseconds: Double
        let framesPerSecond: Double
        let drawableCount: Int
    }

    let deviceName: String

    private let metalDevice: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let terrainRenderer: JungleTerrainRenderer
    private let objectPipelineState: MTLRenderPipelineState
    private let postProcessPipelineState: MTLRenderPipelineState
    private let objectShadowPipelineState: MTLRenderPipelineState
    private let objectDepthStencilState: MTLDepthStencilState
    private let shadowDepthStencilState: MTLDepthStencilState
    private let surfaceSamplerState: MTLSamplerState
    private let postProcessSamplerState: MTLSamplerState
    private let shadowCompareSamplerState: MTLSamplerState
    private let fallbackTexture: MTLTexture
    private let flatNormalTexture: MTLTexture
    private let shadowMapTexture: MTLTexture
    private let materialTextures: [SceneMaterialTextureKey: MTLTexture]
    private let scene: BootstrapScene
    private let inFlightFrameSemaphore: DispatchSemaphore
    private weak var session: GameSession?
    private var sceneColorTexture: MTLTexture?
    private var sceneDepthTexture: MTLTexture?
    private var lastFrameTimestamp: CFTimeInterval?
    private var lastOverlayUpdateTime: CFTimeInterval = 0
    private var lastPerformanceUpdateTime: CFTimeInterval = 0
    private var accumulatedFrameTime: Double = 0
    private var accumulatedFrameCount = 0
    private var nextFrameResourceIndex = 0
    private let sessionUpdateLock = NSLock()
    private var pendingSessionOverlayUpdate: SessionOverlayUpdate?
    private var pendingSessionPerformanceUpdate: SessionPerformanceUpdate?
    private var isSessionUpdateFlushScheduled = false

    init?(view: MTKView, session: GameSession) {
        guard
            let device = view.device,
            let commandQueue = device.makeCommandQueue()
        else {
            return nil
        }

        let scene = BootstrapScene(
            device: device,
            assetRoot: session.assetRootPath,
            worldDataRoot: session.worldDataRootPath,
            worldManifestPath: session.worldManifestPath
        )

        guard
            let library = device.makeDefaultLibrary(),
            let objectVertexFunction = library.makeFunction(name: "bootstrapVertexMain"),
            let objectShadowVertexFunction = library.makeFunction(name: "bootstrapShadowVertexMain"),
            let objectFragmentFunction = library.makeFunction(name: "bootstrapFragmentMain"),
            let fullScreenVertexFunction = library.makeFunction(name: "skyVertexMain"),
            let postProcessFragmentFunction = library.makeFunction(name: "postProcessFragmentMain"),
            let objectPipelineState = Self.makeObjectPipelineState(
                device: device,
                vertexFunction: objectVertexFunction,
                fragmentFunction: objectFragmentFunction,
                colorPixelFormat: Self.sceneColorPixelFormat,
                depthPixelFormat: .depth32Float,
                sampleCount: 1
            ),
            let postProcessPipelineState = Self.makePostProcessPipelineState(
                device: device,
                vertexFunction: fullScreenVertexFunction,
                fragmentFunction: postProcessFragmentFunction,
                colorPixelFormat: view.colorPixelFormat,
                sampleCount: max(view.sampleCount, 1)
            ),
            let objectShadowPipelineState = Self.makeShadowPipelineState(
                device: device,
                vertexFunction: objectShadowVertexFunction,
                depthPixelFormat: .depth32Float
            ),
            let objectDepthStencilState = Self.makeDepthStencilState(
                device: device,
                writeEnabled: true,
                compareFunction: .less
            ),
            let shadowDepthStencilState = Self.makeDepthStencilState(
                device: device,
                writeEnabled: true,
                compareFunction: .less
            ),
            let surfaceSamplerState = Self.makeSurfaceSamplerState(device: device),
            let postProcessSamplerState = Self.makePostProcessSamplerState(device: device),
            let shadowCompareSamplerState = Self.makeShadowCompareSamplerState(device: device),
            let fallbackTexture = Self.makeFallbackTexture(device: device),
            let flatNormalTexture = Self.makeFlatNormalTexture(device: device),
            let shadowMapTexture = Self.makeShadowMapTexture(
                device: device,
                resolution: scene.environment.shadow.mapResolution
            ),
            let terrainRenderer = JungleTerrainRenderer(
                device: device,
                colorPixelFormat: Self.sceneColorPixelFormat,
                depthPixelFormat: .depth32Float,
                shadowDepthPixelFormat: shadowMapTexture.pixelFormat,
                maxFramesInFlight: Self.maxFramesInFlight
            )
        else {
            return nil
        }

        self.deviceName = device.name
        self.metalDevice = device
        self.commandQueue = commandQueue
        self.terrainRenderer = terrainRenderer
        self.objectPipelineState = objectPipelineState
        self.postProcessPipelineState = postProcessPipelineState
        self.objectShadowPipelineState = objectShadowPipelineState
        self.objectDepthStencilState = objectDepthStencilState
        self.shadowDepthStencilState = shadowDepthStencilState
        self.surfaceSamplerState = surfaceSamplerState
        self.postProcessSamplerState = postProcessSamplerState
        self.shadowCompareSamplerState = shadowCompareSamplerState
        self.fallbackTexture = fallbackTexture
        self.flatNormalTexture = flatNormalTexture
        self.shadowMapTexture = shadowMapTexture
        self.inFlightFrameSemaphore = DispatchSemaphore(value: Self.maxFramesInFlight)
        self.session = session
        self.sceneColorTexture = nil
        self.sceneDepthTexture = nil
        let textureLoader = MTKTextureLoader(device: device)
        self.scene = scene
        self.materialTextures = Self.loadMaterialTextures(
            for: scene.drawables,
            with: textureLoader,
            assetRoot: URL(fileURLWithPath: session.assetRootPath, isDirectory: true)
        )

        super.init()

        session.setFreshRunHandler { [weak self] in
            self?.prepareFreshRun()
        }

        scene.configureGameCore()
        configureSpawnFromScene()
        publishSceneMetadata()
        print("[Renderer] Jungle hybrid ready on \(device.name) with \(scene.debugInfo.summary)")
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        session?.updateViewport(size: size)
    }

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let deltaTime = lastFrameTimestamp.map { now - $0 } ?? (1.0 / 60.0)
        lastFrameTimestamp = now
        accumulatedFrameTime += deltaTime
        accumulatedFrameCount += 1

        if session?.shouldAdvanceSimulation ?? false {
            GameCoreTick(deltaTime)
        }

        let snapshot = GameCoreGetSnapshot()
        let cameraPosition = SIMD3<Float>(snapshot.cameraX, snapshot.cameraY, snapshot.cameraZ)
        let forwardVector = RenderMath.forwardVector(
            yawDegrees: snapshot.yawDegrees,
            pitchDegrees: snapshot.pitchDegrees
        )
        let cameraRight = Self.horizontalRightVector(from: forwardVector)
        let scopeActive = session?.isScopeActive ?? false
        let visibilityState = scene.visibilityState(
            for: cameraPosition,
            forwardVector: forwardVector,
            scopeActive: scopeActive
        )
        let streamingState = scene.streamingState(
            for: cameraPosition,
            visibleDrawableCount: visibilityState.drawables.count,
            culledCount: visibilityState.culledCount
        )
        let briefingState = scene.briefingState(for: snapshot)
        let routeState = scene.routeState(for: snapshot)
        let evasionState = scene.evasionState(for: snapshot)

        if now - lastOverlayUpdateTime > 0.12 {
            lastOverlayUpdateTime = now
            enqueueSessionOverlayUpdate(
                SessionOverlayUpdate(
                    snapshot: snapshot,
                    drawableSize: view.drawableSize,
                    briefing: (summary: briefingState.summary, details: briefingState.details),
                    route: (summary: routeState.summary, details: routeState.details),
                    evasion: (summary: evasionState.summary, details: evasionState.details),
                    streaming: (summary: streamingState.summary, details: streamingState.details)
                )
            )
        }

        if now - lastPerformanceUpdateTime > 0.45, accumulatedFrameCount > 0 {
            let averageFrameTime = accumulatedFrameTime / Double(accumulatedFrameCount)
            let framesPerSecond = averageFrameTime > 0 ? (1 / averageFrameTime) : 0
            lastPerformanceUpdateTime = now
            accumulatedFrameTime = 0
            accumulatedFrameCount = 0

            enqueueSessionPerformanceUpdate(
                SessionPerformanceUpdate(
                    milliseconds: averageFrameTime * 1000,
                    framesPerSecond: framesPerSecond,
                    drawableCount: visibilityState.drawables.count
                )
            )
        }

        guard
            let presentationRenderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }

        guard ensureSceneRenderTargets(width: drawable.texture.width, height: drawable.texture.height) else {
            return
        }

        // Reuse one buffer set per in-flight frame so CPU writes never race the GPU.
        inFlightFrameSemaphore.wait()
        let frameResourceIndex = nextFrameResourceIndex
        nextFrameResourceIndex = (nextFrameResourceIndex + 1) % Self.maxFramesInFlight
        let inFlightFrameSemaphore = self.inFlightFrameSemaphore
        var shouldSignalInFlightSemaphore = true
        defer {
            if shouldSignalInFlightSemaphore {
                inFlightFrameSemaphore.signal()
            }
        }

        commandBuffer.addCompletedHandler { _ in
            inFlightFrameSemaphore.signal()
        }

        let aspectRatio = max(Float(view.drawableSize.width / max(view.drawableSize.height, 1)), 0.1)
        let unscopedFieldOfViewY: Float = 60.0 * (.pi / 180.0)
        let scopedFieldOfViewY = session?.scopeFieldOfViewYRadians
            ?? max(scene.scopeConfiguration.fieldOfViewDegrees, 4.0) * (.pi / 180.0)
        let fieldOfViewY = scopeActive ? scopedFieldOfViewY : unscopedFieldOfViewY
        let baseFarPlane = max(scene.environment.fogFar * 1.05, 180.0)
        let scopedFarPlane = max(
            scene.environment.fogFar * (
                session?.scopeFarPlaneMultiplier
                    ?? max(scene.scopeConfiguration.farPlaneMultiplier ?? 1.35, 1.0)
            ),
            baseFarPlane
        )
        let projectionMatrix = simd_float4x4.perspective(
            fieldOfViewY: fieldOfViewY,
            aspectRatio: aspectRatio,
            nearZ: 0.1,
            farZ: scopeActive ? scopedFarPlane : baseFarPlane
        )
        let viewMatrix = simd_float4x4.lookAt(
            eye: cameraPosition,
            center: cameraPosition + forwardVector,
            up: SIMD3<Float>(0, 1, 0)
        )
        let viewProjectionMatrix = projectionMatrix * viewMatrix
        let terrainFrame = scene.makeJungleTerrainFrame(
            snapshot: snapshot,
            cameraPosition: cameraPosition,
            cameraForward: forwardVector,
            cameraRight: cameraRight,
            viewProjectionMatrix: viewProjectionMatrix
        )
        let skyColor = terrainRenderer.skyColor(for: terrainFrame)
        let atmosphereControls = terrainRenderer.atmosphereControls(for: terrainFrame)
        let lightDirection = terrainRenderer.lightDirection(for: terrainFrame)
        let shadowFrame = makeShadowFrame(
            cameraPosition: cameraPosition,
            cameraForward: forwardVector,
            lightDirection: lightDirection,
            scopeActive: scopeActive
        )
        let shadowCasters = scene.shadowCasterDrawables(
            for: cameraPosition,
            scopeActive: scopeActive
        )

        if let shadowRenderPassDescriptor = Self.makeShadowRenderPassDescriptor(texture: shadowMapTexture),
           let shadowEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowRenderPassDescriptor) {
            shadowEncoder.label = "SunShadowPass"
            shadowEncoder.setDepthStencilState(shadowDepthStencilState)
            shadowEncoder.setCullMode(.back)
            shadowEncoder.setFrontFacing(.counterClockwise)
            shadowEncoder.setDepthBias(
                scene.environment.shadow.depthBias,
                slopeScale: 1.75,
                clamp: max(scene.environment.shadow.depthBias * 4.0, 0.01)
            )
            terrainRenderer.drawShadowPass(
                in: shadowEncoder,
                frame: terrainFrame,
                shadowFrame: shadowFrame,
                frameResourceIndex: frameResourceIndex
            )
            drawShadowCasters(
                shadowCasters,
                encoder: shadowEncoder,
                shadowFrame: shadowFrame
            )
            shadowEncoder.endEncoding()
        }

        guard
            let sceneColorTexture,
            let sceneDepthTexture,
            let sceneRenderPassDescriptor = Self.makeSceneRenderPassDescriptor(
                colorTexture: sceneColorTexture,
                depthTexture: sceneDepthTexture,
                clearColor: skyColor
            ),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: sceneRenderPassDescriptor)
        else {
            return
        }

        encoder.label = "JungleTerrainAndSolidObjectsPass"
        terrainRenderer.draw(
            in: encoder,
            frame: terrainFrame,
            shadowFrame: shadowFrame,
            shadowTexture: shadowMapTexture,
            shadowSamplerState: shadowCompareSamplerState,
            frameResourceIndex: frameResourceIndex
        ) { [weak self] encoder in
            guard let self else {
                return
            }

            self.drawSolidObjects(
                visibilityState.drawables,
                encoder: encoder,
                viewProjectionMatrix: viewProjectionMatrix,
                cameraPosition: cameraPosition,
                terrainFrame: terrainFrame,
                lightDirection: lightDirection,
                shadowFrame: shadowFrame,
                skyColor: skyColor,
                atmosphereControls: atmosphereControls
            )
        }
        encoder.endEncoding()

        presentationRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        presentationRenderPassDescriptor.colorAttachments[0].storeAction = .store
        presentationRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 1
        )
        presentationRenderPassDescriptor.depthAttachment.loadAction = .dontCare
        presentationRenderPassDescriptor.depthAttachment.storeAction = .dontCare

        guard let postProcessEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: presentationRenderPassDescriptor) else {
            return
        }

        drawPostProcessedScene(
            from: sceneColorTexture,
            encoder: postProcessEncoder
        )
        postProcessEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
        shouldSignalInFlightSemaphore = false
    }

    private func enqueueSessionOverlayUpdate(_ update: SessionOverlayUpdate) {
        sessionUpdateLock.lock()
        pendingSessionOverlayUpdate = update
        let shouldScheduleFlush = !isSessionUpdateFlushScheduled
        if shouldScheduleFlush {
            isSessionUpdateFlushScheduled = true
        }
        sessionUpdateLock.unlock()

        guard shouldScheduleFlush else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.flushPendingSessionUpdates()
        }
    }

    private func enqueueSessionPerformanceUpdate(_ update: SessionPerformanceUpdate) {
        sessionUpdateLock.lock()
        pendingSessionPerformanceUpdate = update
        let shouldScheduleFlush = !isSessionUpdateFlushScheduled
        if shouldScheduleFlush {
            isSessionUpdateFlushScheduled = true
        }
        sessionUpdateLock.unlock()

        guard shouldScheduleFlush else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.flushPendingSessionUpdates()
        }
    }

    private func flushPendingSessionUpdates() {
        let overlayUpdate: SessionOverlayUpdate?
        let performanceUpdate: SessionPerformanceUpdate?

        sessionUpdateLock.lock()
        overlayUpdate = pendingSessionOverlayUpdate
        pendingSessionOverlayUpdate = nil
        performanceUpdate = pendingSessionPerformanceUpdate
        pendingSessionPerformanceUpdate = nil
        isSessionUpdateFlushScheduled = false
        sessionUpdateLock.unlock()

        if let overlayUpdate {
            session?.applyRendererUpdate(
                snapshot: overlayUpdate.snapshot,
                drawableSize: overlayUpdate.drawableSize,
                briefing: overlayUpdate.briefing,
                route: overlayUpdate.route,
                evasion: overlayUpdate.evasion,
                streaming: overlayUpdate.streaming,
                frameTiming: performanceUpdate.map { performanceUpdate in
                    (
                        milliseconds: performanceUpdate.milliseconds,
                        framesPerSecond: performanceUpdate.framesPerSecond,
                        drawableCount: performanceUpdate.drawableCount
                    )
                }
            )
        } else if let performanceUpdate {
            session?.applyRendererFrameTimingUpdate(
                milliseconds: performanceUpdate.milliseconds,
                framesPerSecond: performanceUpdate.framesPerSecond,
                drawableCount: performanceUpdate.drawableCount
            )
        }

        sessionUpdateLock.lock()
        let shouldScheduleFlush = (pendingSessionOverlayUpdate != nil || pendingSessionPerformanceUpdate != nil)
            && !isSessionUpdateFlushScheduled
        if shouldScheduleFlush {
            isSessionUpdateFlushScheduled = true
        }
        sessionUpdateLock.unlock()

        guard shouldScheduleFlush else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.flushPendingSessionUpdates()
        }
    }

    private func drawSolidObjects(
        _ drawables: [SceneDrawable],
        encoder: MTLRenderCommandEncoder,
        viewProjectionMatrix: simd_float4x4,
        cameraPosition: SIMD3<Float>,
        terrainFrame: JungleTerrainFrame,
        lightDirection: SIMD3<Float>,
        shadowFrame: RendererShadowFrame,
        skyColor: SIMD3<Float>,
        atmosphereControls: SIMD4<Float>
    ) {
        guard !drawables.isEmpty else {
            return
        }

        let baseFogColor = SIMD3<Float>(
            scene.environment.fogColor.x,
            scene.environment.fogColor.y,
            scene.environment.fogColor.z
        )
        let fogColor = Self.mix(baseFogColor, skyColor, t: 0.65)
        let fogNear = max(terrainFrame.visibilityDistance * max(atmosphereControls.x, 0.18), 12)
        let fogFar = max(terrainFrame.visibilityDistance, fogNear + 1)

        encoder.setRenderPipelineState(objectPipelineState)
        encoder.setDepthStencilState(objectDepthStencilState)
        encoder.setCullMode(.back)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setFragmentSamplerState(surfaceSamplerState, index: 0)
        encoder.setFragmentSamplerState(shadowCompareSamplerState, index: 1)

        for drawable in drawables {
            var uniforms = SceneUniforms(
                viewProjectionMatrix: viewProjectionMatrix,
                shadowViewProjectionMatrix: shadowFrame.viewProjectionMatrix,
                modelMatrix: drawable.modelMatrix,
                lightDirection: SIMD4<Float>(
                    -lightDirection.x,
                    -lightDirection.y,
                    -lightDirection.z,
                    0
                ),
                sunColor: SIMD4<Float>(
                    scene.environment.sunColor.x,
                    scene.environment.sunColor.y,
                    scene.environment.sunColor.z,
                    1
                ),
                cameraPosition: SIMD4<Float>(cameraPosition.x, cameraPosition.y, cameraPosition.z, 1),
                fogColor: SIMD4<Float>(fogColor.x, fogColor.y, fogColor.z, 1),
                lightingParameters: SIMD4<Float>(
                    scene.environment.ambientIntensity,
                    scene.environment.diffuseIntensity,
                    fogNear,
                    fogFar
                ),
                atmosphereParameters: SIMD4<Float>(atmosphereControls.x, 0, 0, 0),
                shadowParameters: SIMD4<Float>(
                    drawable.receivesShadow ? shadowFrame.strength : 0.0,
                    shadowFrame.normalBias,
                    shadowFrame.texelSize,
                    0
                )
            )
            var materialUniforms = SceneMaterialUniforms(
                baseColorFactor: drawable.material.baseColorFactor,
                channelFactors: SIMD4<Float>(
                    drawable.material.roughnessFactor,
                    drawable.material.ambientOcclusionStrength,
                    drawable.material.normalScale,
                    0
                )
            )

            encoder.setVertexBuffer(drawable.vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&materialUniforms, length: MemoryLayout<SceneMaterialUniforms>.stride, index: 2)
            encoder.setFragmentTexture(materialTexture(for: drawable.material.albedoTexture, semantic: .albedo) ?? fallbackTexture, index: 0)
            encoder.setFragmentTexture(materialTexture(for: drawable.material.normalTexture, semantic: .normal) ?? flatNormalTexture, index: 1)
            encoder.setFragmentTexture(materialTexture(for: drawable.material.roughnessTexture, semantic: .roughness) ?? fallbackTexture, index: 2)
            encoder.setFragmentTexture(materialTexture(for: drawable.material.ambientOcclusionTexture, semantic: .ambientOcclusion) ?? fallbackTexture, index: 3)
            encoder.setFragmentTexture(shadowMapTexture, index: 4)
            encoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: drawable.vertexCount
            )
        }
    }

    private func drawShadowCasters(
        _ drawables: [SceneDrawable],
        encoder: MTLRenderCommandEncoder,
        shadowFrame: RendererShadowFrame
    ) {
        guard !drawables.isEmpty else {
            return
        }

        encoder.setRenderPipelineState(objectShadowPipelineState)
        encoder.setDepthStencilState(shadowDepthStencilState)
        encoder.setCullMode(.back)
        encoder.setFrontFacing(.counterClockwise)

        for drawable in drawables where drawable.castsShadow {
            var uniforms = SceneUniforms(
                viewProjectionMatrix: .identity(),
                shadowViewProjectionMatrix: shadowFrame.viewProjectionMatrix,
                modelMatrix: drawable.modelMatrix,
                lightDirection: SIMD4<Float>(0, 0, 0, 0),
                sunColor: SIMD4<Float>(0, 0, 0, 0),
                cameraPosition: SIMD4<Float>(0, 0, 0, 0),
                fogColor: SIMD4<Float>(0, 0, 0, 0),
                lightingParameters: SIMD4<Float>(0, 0, 0, 0),
                atmosphereParameters: SIMD4<Float>(0, 0, 0, 0),
                shadowParameters: SIMD4<Float>(0, 0, 0, 0)
            )

            encoder.setVertexBuffer(drawable.vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)
            encoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: drawable.vertexCount
            )
        }
    }

    private func drawPostProcessedScene(
        from sceneTexture: MTLTexture,
        encoder: MTLRenderCommandEncoder
    ) {
        var uniforms = ScenePostProcessUniforms(
            exposureParameters: SIMD4<Float>(
                scene.environment.postProcess.exposureBias,
                scene.environment.postProcess.whitePoint,
                scene.environment.postProcess.contrast,
                scene.environment.postProcess.saturation
            ),
            shadowTint: scene.environment.postProcess.shadowTint,
            highlightTint: scene.environment.postProcess.highlightTint,
            gradeParameters: SIMD4<Float>(
                scene.environment.postProcess.shadowBalance,
                scene.environment.postProcess.vignetteStrength,
                0,
                0
            )
        )

        encoder.label = "ScenePostProcessPass"
        encoder.setRenderPipelineState(postProcessPipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<ScenePostProcessUniforms>.stride, index: 0)
        encoder.setFragmentTexture(sceneTexture, index: 0)
        encoder.setFragmentSamplerState(postProcessSamplerState, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    }

    private func ensureSceneRenderTargets(width: Int, height: Int) -> Bool {
        guard width > 0, height > 0 else {
            return false
        }

        if
            let sceneColorTexture,
            let sceneDepthTexture,
            sceneColorTexture.width == width,
            sceneColorTexture.height == height,
            sceneDepthTexture.width == width,
            sceneDepthTexture.height == height
        {
            return true
        }

        sceneColorTexture = Self.makeSceneColorTexture(
            device: metalDevice,
            width: width,
            height: height
        )
        sceneDepthTexture = Self.makeSceneDepthTexture(
            device: metalDevice,
            width: width,
            height: height
        )

        return sceneColorTexture != nil && sceneDepthTexture != nil
    }

    private func materialTexture(
        for reference: SceneTextureReference?,
        semantic: SceneMaterialTextureSemantic
    ) -> MTLTexture? {
        guard let reference else {
            return nil
        }

        return materialTextures[SceneMaterialTextureKey(reference: reference, semantic: semantic)]
    }

    private func prepareFreshRun() {
        scene.prepareFreshRun()
        configureSpawnFromScene()
        publishSceneMetadata()
    }

    private func configureSpawnFromScene() {
        let spawn = scene.debugInfo.spawn.positionVector
        GameCoreConfigureSpawn(
            spawn.x,
            spawn.y,
            spawn.z,
            scene.debugInfo.spawn.yawDegrees,
            scene.debugInfo.spawn.pitchDegrees
        )
    }

    private func publishSceneMetadata() {
        guard let session else {
            return
        }

        let debugInfo = scene.debugInfo
        let scopeConfiguration = scene.scopeConfiguration
        let mapConfiguration = scene.mapConfiguration
        DispatchQueue.main.async {
            session.noteSceneBootstrap(
                label: debugInfo.sceneName,
                summary: debugInfo.summary,
                details: debugInfo.details,
                overlayTitle: debugInfo.cycleLabel,
                scopeConfiguration: scopeConfiguration,
                mapConfiguration: mapConfiguration
            )
        }
    }

    private static func horizontalRightVector(from forwardVector: SIMD3<Float>) -> SIMD3<Float> {
        let horizontal = SIMD3<Float>(-forwardVector.z, 0, forwardVector.x)
        let lengthSquared = simd_length_squared(horizontal)
        guard lengthSquared > 0.000_001 else {
            return SIMD3<Float>(1, 0, 0)
        }

        return simd_normalize(horizontal)
    }

    private func makeShadowFrame(
        cameraPosition: SIMD3<Float>,
        cameraForward: SIMD3<Float>,
        lightDirection: SIMD3<Float>,
        scopeActive: Bool
    ) -> RendererShadowFrame {
        let settings = scene.environment.shadow
        let coverage = max(
            settings.coverage * (scopeActive ? settings.scopeCoverageMultiplier : 1.0),
            24.0
        )
        let horizontalForward = Self.horizontalForwardVector(from: cameraForward)
        let focusCenter = cameraPosition + horizontalForward * (coverage * settings.forwardOffsetMultiplier)
        let lightUpVector = Self.shadowUpVector(for: lightDirection)
        let lightViewMatrix = simd_float4x4.lookAt(
            eye: focusCenter - lightDirection * max(coverage * 2.0, 120.0),
            center: focusCenter,
            up: lightUpVector
        )

        let horizontalExtent = coverage
        let verticalExtent = max(coverage * 0.8, 42.0)
        let lowerExtent = max(verticalExtent * 0.55, 18.0)
        let depthPadding = max(coverage, 48.0)
        let corners = Self.shadowBoundsCorners(
            center: focusCenter,
            horizontalExtent: horizontalExtent,
            lowerExtent: lowerExtent,
            upperExtent: verticalExtent
        )

        var minimum = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var maximum = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        for corner in corners {
            let lightSpaceCorner = lightViewMatrix * SIMD4<Float>(corner.x, corner.y, corner.z, 1)
            let lightSpacePoint = SIMD3<Float>(lightSpaceCorner.x, lightSpaceCorner.y, lightSpaceCorner.z)
            minimum = simd_min(minimum, lightSpacePoint)
            maximum = simd_max(maximum, lightSpacePoint)
        }

        let projectionWidth = max(maximum.x - minimum.x, 1.0)
        let projectionHeight = max(maximum.y - minimum.y, 1.0)
        let lightSpaceCenter = (minimum + maximum) * 0.5
        let texelWidth = projectionWidth / Float(settings.mapResolution)
        let texelHeight = projectionHeight / Float(settings.mapResolution)
        let snappedCenterX = round(lightSpaceCenter.x / max(texelWidth, 0.0001)) * max(texelWidth, 0.0001)
        let snappedCenterY = round(lightSpaceCenter.y / max(texelHeight, 0.0001)) * max(texelHeight, 0.0001)
        let left = snappedCenterX - (projectionWidth * 0.5)
        let right = snappedCenterX + (projectionWidth * 0.5)
        let bottom = snappedCenterY - (projectionHeight * 0.5)
        let top = snappedCenterY + (projectionHeight * 0.5)
        let nearZ = minimum.z - depthPadding
        let farZ = maximum.z + depthPadding
        let shadowProjectionMatrix = simd_float4x4.orthographic(
            left: left,
            right: right,
            bottom: bottom,
            top: top,
            nearZ: nearZ,
            farZ: farZ
        )

        return RendererShadowFrame(
            viewProjectionMatrix: shadowProjectionMatrix * lightViewMatrix,
            strength: settings.strength,
            normalBias: settings.normalBias,
            texelSize: 1.0 / Float(settings.mapResolution)
        )
    }

    private static func horizontalForwardVector(from forwardVector: SIMD3<Float>) -> SIMD3<Float> {
        let horizontal = SIMD3<Float>(forwardVector.x, 0, forwardVector.z)
        let lengthSquared = simd_length_squared(horizontal)
        guard lengthSquared > 0.000_001 else {
            return SIMD3<Float>(0, 0, -1)
        }

        return simd_normalize(horizontal)
    }

    private static func shadowUpVector(for lightDirection: SIMD3<Float>) -> SIMD3<Float> {
        let worldUp = SIMD3<Float>(0, 1, 0)
        return abs(simd_dot(lightDirection, worldUp)) > 0.92
            ? SIMD3<Float>(0, 0, 1)
            : worldUp
    }

    private static func shadowBoundsCorners(
        center: SIMD3<Float>,
        horizontalExtent: Float,
        lowerExtent: Float,
        upperExtent: Float
    ) -> [SIMD3<Float>] {
        [
            SIMD3<Float>(center.x - horizontalExtent, center.y - lowerExtent, center.z - horizontalExtent),
            SIMD3<Float>(center.x - horizontalExtent, center.y - lowerExtent, center.z + horizontalExtent),
            SIMD3<Float>(center.x + horizontalExtent, center.y - lowerExtent, center.z - horizontalExtent),
            SIMD3<Float>(center.x + horizontalExtent, center.y - lowerExtent, center.z + horizontalExtent),
            SIMD3<Float>(center.x - horizontalExtent, center.y + upperExtent, center.z - horizontalExtent),
            SIMD3<Float>(center.x - horizontalExtent, center.y + upperExtent, center.z + horizontalExtent),
            SIMD3<Float>(center.x + horizontalExtent, center.y + upperExtent, center.z - horizontalExtent),
            SIMD3<Float>(center.x + horizontalExtent, center.y + upperExtent, center.z + horizontalExtent),
        ]
    }

    private static func makeObjectPipelineState(
        device: MTLDevice,
        vertexFunction: MTLFunction,
        fragmentFunction: MTLFunction,
        colorPixelFormat: MTLPixelFormat,
        depthPixelFormat: MTLPixelFormat,
        sampleCount: Int
    ) -> MTLRenderPipelineState? {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "SolidObjectOverlayPipeline"
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.depthAttachmentPixelFormat = depthPixelFormat
        descriptor.rasterSampleCount = sampleCount
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private static func makePostProcessPipelineState(
        device: MTLDevice,
        vertexFunction: MTLFunction,
        fragmentFunction: MTLFunction,
        colorPixelFormat: MTLPixelFormat,
        sampleCount: Int
    ) -> MTLRenderPipelineState? {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "ScenePostProcessPipeline"
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.rasterSampleCount = sampleCount
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private static func makeShadowPipelineState(
        device: MTLDevice,
        vertexFunction: MTLFunction,
        depthPixelFormat: MTLPixelFormat
    ) -> MTLRenderPipelineState? {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "SolidObjectShadowPipeline"
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = nil
        descriptor.depthAttachmentPixelFormat = depthPixelFormat
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private static func makeDepthStencilState(
        device: MTLDevice,
        writeEnabled: Bool,
        compareFunction: MTLCompareFunction
    ) -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = writeEnabled
        descriptor.depthCompareFunction = compareFunction
        return device.makeDepthStencilState(descriptor: descriptor)
    }

    private static func makeSurfaceSamplerState(device: MTLDevice) -> MTLSamplerState? {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.maxAnisotropy = 8
        return device.makeSamplerState(descriptor: samplerDescriptor)
    }

    private static func makePostProcessSamplerState(device: MTLDevice) -> MTLSamplerState? {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .notMipmapped
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        return device.makeSamplerState(descriptor: samplerDescriptor)
    }

    private static func makeShadowCompareSamplerState(device: MTLDevice) -> MTLSamplerState? {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .notMipmapped
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.compareFunction = .lessEqual
        return device.makeSamplerState(descriptor: samplerDescriptor)
    }

    private static func makeFallbackTexture(device: MTLDevice) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: 1,
            height: 1,
            mipmapped: false
        )
        descriptor.usage = .shaderRead

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }

        var pixel: [UInt8] = [255, 255, 255, 255]
        texture.replace(
            region: MTLRegionMake2D(0, 0, 1, 1),
            mipmapLevel: 0,
            withBytes: &pixel,
            bytesPerRow: 4
        )
        texture.label = "Fallback White Texture"
        return texture
    }

    private static func makeFlatNormalTexture(device: MTLDevice) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: 1,
            height: 1,
            mipmapped: false
        )
        descriptor.usage = .shaderRead

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }

        var pixel: [UInt8] = [128, 128, 255, 255]
        texture.replace(
            region: MTLRegionMake2D(0, 0, 1, 1),
            mipmapLevel: 0,
            withBytes: &pixel,
            bytesPerRow: 4
        )
        texture.label = "Fallback Normal Texture"
        return texture
    }

    private static func makeSceneColorTexture(
        device: MTLDevice,
        width: Int,
        height: Int
    ) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: sceneColorPixelFormat,
            width: max(width, 1),
            height: max(height, 1),
            mipmapped: false
        )
        descriptor.storageMode = .private
        descriptor.usage = [.renderTarget, .shaderRead]
        let texture = device.makeTexture(descriptor: descriptor)
        texture?.label = "SceneHDRColor"
        return texture
    }

    private static func makeSceneDepthTexture(
        device: MTLDevice,
        width: Int,
        height: Int
    ) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: max(width, 1),
            height: max(height, 1),
            mipmapped: false
        )
        descriptor.storageMode = .private
        descriptor.usage = .renderTarget
        let texture = device.makeTexture(descriptor: descriptor)
        texture?.label = "SceneHDRDepth"
        return texture
    }

    private static func makeShadowMapTexture(
        device: MTLDevice,
        resolution: Int
    ) -> MTLTexture? {
        let normalizedResolution = max(resolution, 512)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: normalizedResolution,
            height: normalizedResolution,
            mipmapped: false
        )
        descriptor.storageMode = .private
        descriptor.usage = [.renderTarget, .shaderRead]
        let texture = device.makeTexture(descriptor: descriptor)
        texture?.label = "SunShadowMap"
        return texture
    }

    private static func makeSceneRenderPassDescriptor(
        colorTexture: MTLTexture,
        depthTexture: MTLTexture,
        clearColor: SIMD3<Float>
    ) -> MTLRenderPassDescriptor? {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = colorTexture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: Double(clearColor.x),
            green: Double(clearColor.y),
            blue: Double(clearColor.z),
            alpha: 1.0
        )
        descriptor.depthAttachment.texture = depthTexture
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .dontCare
        descriptor.depthAttachment.clearDepth = 1.0
        return descriptor
    }

    private static func makeShadowRenderPassDescriptor(texture: MTLTexture) -> MTLRenderPassDescriptor? {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.depthAttachment.texture = texture
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .store
        descriptor.depthAttachment.clearDepth = 1.0
        return descriptor
    }

    private static func loadMaterialTextures(
        for drawables: [SceneDrawable],
        with loader: MTKTextureLoader,
        assetRoot: URL
    ) -> [SceneMaterialTextureKey: MTLTexture] {
        var requestedTextures: Set<SceneMaterialTextureKey> = []

        for drawable in drawables {
            if let reference = drawable.material.albedoTexture {
                requestedTextures.insert(SceneMaterialTextureKey(reference: reference, semantic: .albedo))
            }
            if let reference = drawable.material.normalTexture {
                requestedTextures.insert(SceneMaterialTextureKey(reference: reference, semantic: .normal))
            }
            if let reference = drawable.material.roughnessTexture {
                requestedTextures.insert(SceneMaterialTextureKey(reference: reference, semantic: .roughness))
            }
            if let reference = drawable.material.ambientOcclusionTexture {
                requestedTextures.insert(SceneMaterialTextureKey(reference: reference, semantic: .ambientOcclusion))
            }
        }

        var textures: [SceneMaterialTextureKey: MTLTexture] = [:]

        for textureKey in requestedTextures {
            let textureURL = textureURL(for: textureKey.reference, assetRoot: assetRoot)
            guard FileManager.default.fileExists(atPath: textureURL.path) else {
                print("[Renderer] Missing material texture at \(textureURL.path)")
                continue
            }

            do {
                let texture = try loader.newTexture(
                    URL: textureURL,
                    options: [
                        MTKTextureLoader.Option.SRGB: textureKey.semantic == .albedo,
                        MTKTextureLoader.Option.generateMipmaps: true,
                    ]
                )
                texture.label = textureURL.lastPathComponent
                textures[textureKey] = texture
            } catch {
                print("[Renderer] Failed to load texture \(textureURL.lastPathComponent): \(error)")
            }
        }

        return textures
    }

    private static func textureURL(
        for reference: SceneTextureReference,
        assetRoot: URL
    ) -> URL {
        switch reference {
        case .sceneKey(let textureKey):
            return assetRoot
                .appendingPathComponent("Textures", isDirectory: true)
                .appendingPathComponent("Final", isDirectory: true)
                .appendingPathComponent(textureKey.rawValue)
        case .assetRelativePath(let relativePath):
            return assetRoot.appendingPathComponent(relativePath)
        }
    }

    private static func mix(_ start: SIMD3<Float>, _ end: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        start + (end - start) * simd_clamp(t, 0.0, 1.0)
    }
}

private final class JungleTerrainRenderer {
    private struct TerrainFrameResources {
        var uniformBuffer: MTLBuffer
        var vertexBuffers: [MTLBuffer?]
        var vertexCapacity = 0
    }

    private struct TerrainVertex {
        var position: SIMD3<Float>
        var color: SIMD4<Float>
        var motion: Float
    }

    private struct TerrainUniforms {
        var viewProjectionMatrix: simd_float4x4
        var shadowViewProjectionMatrix: simd_float4x4
        var cameraPositionAndTime: SIMD4<Float>
        var skyColorAndVisibility: SIMD4<Float>
        var atmosphereControls: SIMD4<Float>
        var shadowParameters: SIMD4<Float>
    }

    private enum TerrainLayerKind {
        case ground
        case understory
        case midstory
        case canopy
    }

    private struct TerrainLayerDefinition {
        var kind: TerrainLayerKind
        var isOpaque: Bool
        var heightScale: Float
        var parallaxDepth: Float
        var lateralDrift: Float
        var alphaScale: Float
    }

    private struct TerrainPayload {
        var layer: TerrainLayerDefinition
        var vertexBuffer: MTLBuffer
        var indexBuffer: MTLBuffer
        var indexCount: Int
    }

    private static let terrainLayers: [TerrainLayerDefinition] = [
        TerrainLayerDefinition(
            kind: .ground,
            isOpaque: true,
            heightScale: 0.0,
            parallaxDepth: 0.0,
            lateralDrift: 0.0,
            alphaScale: 1.0
        ),
        TerrainLayerDefinition(
            kind: .understory,
            isOpaque: false,
            heightScale: 0.74,
            parallaxDepth: 0.10,
            lateralDrift: 0.05,
            alphaScale: 0.44
        ),
        TerrainLayerDefinition(
            kind: .midstory,
            isOpaque: false,
            heightScale: 0.58,
            parallaxDepth: 0.22,
            lateralDrift: 0.09,
            alphaScale: 0.34
        ),
        TerrainLayerDefinition(
            kind: .canopy,
            isOpaque: false,
            heightScale: 0.46,
            parallaxDepth: 0.36,
            lateralDrift: 0.14,
            alphaScale: 0.28
        ),
    ]

    private static let debugLayerLiftMultiplier: Float = 5.0

    private static let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct TerrainVertexIn {
        float3 position [[attribute(0)]];
        float4 color [[attribute(1)]];
        float motion [[attribute(2)]];
    };

    struct TerrainUniforms {
        float4x4 viewProjectionMatrix;
        float4x4 shadowViewProjectionMatrix;
        float4 cameraPositionAndTime;
        float4 skyColorAndVisibility;
        float4 atmosphereControls;
        float4 shadowParameters;
    };

    struct TerrainRasterizerData {
        float4 position [[position]];
        float4 color;
        float3 worldPosition;
        float4 shadowPosition;
    };

    vertex TerrainRasterizerData jungleTerrainVertex(
        TerrainVertexIn in [[stage_in]],
        constant TerrainUniforms &uniforms [[buffer(1)]]
    ) {
        TerrainRasterizerData out;
        float time = uniforms.cameraPositionAndTime.w;
        float wind = sin((in.position.x * 0.05f) + (in.position.z * 0.04f) + time * 0.9f);
        float3 animatedPosition = in.position;
        animatedPosition.y += wind * in.motion * 0.06f;
        out.position = uniforms.viewProjectionMatrix * float4(animatedPosition, 1.0f);
        out.color = in.color;
        out.worldPosition = animatedPosition;
        out.shadowPosition = uniforms.shadowViewProjectionMatrix * float4(animatedPosition, 1.0f);
        return out;
    }

    vertex float4 jungleTerrainShadowVertex(
        TerrainVertexIn in [[stage_in]],
        constant TerrainUniforms &uniforms [[buffer(1)]]
    ) {
        float time = uniforms.cameraPositionAndTime.w;
        float wind = sin((in.position.x * 0.05f) + (in.position.z * 0.04f) + time * 0.9f);
        float3 animatedPosition = in.position;
        animatedPosition.y += wind * in.motion * 0.06f;
        return uniforms.shadowViewProjectionMatrix * float4(animatedPosition, 1.0f);
    }

    float sampleTerrainShadowVisibility(
        float4 shadowPosition,
        constant TerrainUniforms &uniforms,
        depth2d<float> shadowTexture,
        sampler shadowSampler
    ) {
        float shadowStrength = clamp(uniforms.shadowParameters.x, 0.0, 1.0);
        if (shadowStrength <= 0.001 || shadowPosition.w <= 0.0001) {
            return 1.0;
        }

        float3 projected = shadowPosition.xyz / shadowPosition.w;
        float2 uv = projected.xy * 0.5 + 0.5;
        float depth = projected.z * 0.5 + 0.5;
        if (
            uv.x <= 0.001 || uv.x >= 0.999 ||
            uv.y <= 0.001 || uv.y >= 0.999 ||
            depth <= 0.0 || depth >= 1.0
        ) {
            return 1.0;
        }

        float texelSize = max(uniforms.shadowParameters.z, 1.0 / 8192.0);
        float receiverBias = max(uniforms.shadowParameters.y, 0.0);
        float comparisonDepth = saturate(depth - receiverBias);

        float visibility = 0.0;
        visibility += shadowTexture.sample_compare(shadowSampler, uv, comparisonDepth);
        visibility += shadowTexture.sample_compare(shadowSampler, uv + float2(texelSize, 0.0), comparisonDepth);
        visibility += shadowTexture.sample_compare(shadowSampler, uv + float2(0.0, texelSize), comparisonDepth);
        visibility += shadowTexture.sample_compare(shadowSampler, uv + float2(texelSize, texelSize), comparisonDepth);
        visibility *= 0.25;

        return 1.0 - ((1.0 - visibility) * shadowStrength);
    }

    fragment float4 jungleTerrainFragment(
        TerrainRasterizerData in [[stage_in]],
        constant TerrainUniforms &uniforms [[buffer(0)]],
        depth2d<float> shadowTexture [[texture(0)]],
        sampler shadowSampler [[sampler(0)]]
    ) {
        float visibilityDistance = max(uniforms.skyColorAndVisibility.w, 1.0f);
        float distanceToCamera = distance(in.worldPosition, uniforms.cameraPositionAndTime.xyz);
        float fogStart = visibilityDistance * clamp(uniforms.atmosphereControls.x, 0.05f, 0.9f);
        float fogRange = max(visibilityDistance - fogStart, 1.0f);
        float fogProgress = saturate((distanceToCamera - fogStart) / fogRange);
        fogProgress = smoothstep(0.0f, 1.0f, fogProgress);
        float fog = pow(fogProgress, max(uniforms.atmosphereControls.y, 0.35f));
        float contrastAmount = mix(1.0f, uniforms.atmosphereControls.z, fogProgress);
        float3 contrastPivot = float3(0.42f);
        float3 contrasted = saturate((in.color.rgb - contrastPivot) * contrastAmount + contrastPivot);
        float3 atmosphereColor = mix(
            uniforms.skyColorAndVisibility.rgb * 0.84f,
            uniforms.skyColorAndVisibility.rgb,
            saturate(uniforms.atmosphereControls.w)
        );
        float3 color = mix(contrasted, atmosphereColor, fog);
        color *= sampleTerrainShadowVisibility(
            in.shadowPosition,
            uniforms,
            shadowTexture,
            shadowSampler
        );
        float alpha = saturate(in.color.a * mix(1.0f, 0.74f, fogProgress));
        return float4(color, alpha);
    }
    """

    private let metalDevice: MTLDevice
    private let solidPipelineState: MTLRenderPipelineState
    private let alphaPipelineState: MTLRenderPipelineState
    private let shadowPipelineState: MTLRenderPipelineState
    private let solidDepthStencilState: MTLDepthStencilState
    private let alphaDepthStencilState: MTLDepthStencilState
    private let maxFramesInFlight: Int
    private var cachedIndexBuffers: [Int: (buffer: MTLBuffer, indexCount: Int)] = [:]
    private var frameResources: [TerrainFrameResources] = []

    init?(
        device: MTLDevice,
        colorPixelFormat: MTLPixelFormat,
        depthPixelFormat: MTLPixelFormat,
        shadowDepthPixelFormat: MTLPixelFormat,
        maxFramesInFlight: Int
    ) {
        guard
            let library = try? device.makeLibrary(source: Self.shaderSource, options: nil),
            let vertexFunction = library.makeFunction(name: "jungleTerrainVertex"),
            let shadowVertexFunction = library.makeFunction(name: "jungleTerrainShadowVertex"),
            let fragmentFunction = library.makeFunction(name: "jungleTerrainFragment")
        else {
            return nil
        }

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[2].format = .float
        vertexDescriptor.attributes[2].offset =
            MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD4<Float>>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<TerrainVertex>.stride

        guard
            let solidPipelineState = Self.makePipelineState(
                device: device,
                vertexFunction: vertexFunction,
                fragmentFunction: fragmentFunction,
                vertexDescriptor: vertexDescriptor,
                colorPixelFormat: colorPixelFormat,
                depthPixelFormat: depthPixelFormat,
                blendingEnabled: false
            ),
            let alphaPipelineState = Self.makePipelineState(
                device: device,
                vertexFunction: vertexFunction,
                fragmentFunction: fragmentFunction,
                vertexDescriptor: vertexDescriptor,
                colorPixelFormat: colorPixelFormat,
                depthPixelFormat: depthPixelFormat,
                blendingEnabled: true
            ),
            let solidDepthStencilState = Self.makeDepthStencilState(
                device: device,
                writeEnabled: true,
                compareFunction: .less
            ),
            let alphaDepthStencilState = Self.makeDepthStencilState(
                device: device,
                writeEnabled: false,
                compareFunction: .lessEqual
            ),
            let shadowPipelineState = Self.makeShadowPipelineState(
                device: device,
                vertexFunction: shadowVertexFunction,
                vertexDescriptor: vertexDescriptor,
                depthPixelFormat: shadowDepthPixelFormat
            )
        else {
            return nil
        }

        self.metalDevice = device
        self.solidPipelineState = solidPipelineState
        self.alphaPipelineState = alphaPipelineState
        self.shadowPipelineState = shadowPipelineState
        self.solidDepthStencilState = solidDepthStencilState
        self.alphaDepthStencilState = alphaDepthStencilState
        self.maxFramesInFlight = max(maxFramesInFlight, 1)
        self.frameResources.reserveCapacity(self.maxFramesInFlight)

        for frameIndex in 0..<self.maxFramesInFlight {
            guard let uniformBuffer = device.makeBuffer(
                length: MemoryLayout<TerrainUniforms>.stride,
                options: .storageModeShared
            ) else {
                return nil
            }

            uniformBuffer.label = "JungleTerrainUniformBuffer[\(frameIndex)]"
            self.frameResources.append(
                TerrainFrameResources(
                    uniformBuffer: uniformBuffer,
                    vertexBuffers: Array(repeating: nil, count: Self.terrainLayers.count)
                )
            )
        }
    }

    func draw(
        in encoder: MTLRenderCommandEncoder,
        frame: JungleTerrainFrame,
        shadowFrame: RendererShadowFrame,
        shadowTexture: MTLTexture,
        shadowSamplerState: MTLSamplerState,
        frameResourceIndex: Int,
        solidObjectDrawer: (MTLRenderCommandEncoder) -> Void
    ) {
        let resourceIndex = normalizedFrameResourceIndex(frameResourceIndex)
        guard
            let terrainPayloads = makeTerrainPayloads(
                for: frame,
                frameResourceIndex: resourceIndex
            ),
            let uniformBuffer = updateUniformBuffer(
                for: frame,
                skyColor: skyColor(for: frame),
                atmosphereControls: atmosphereControls(for: frame),
                shadowFrame: shadowFrame,
                frameResourceIndex: resourceIndex
            )
        else {
            solidObjectDrawer(encoder)
            return
        }

        drawTerrainPayloads(
            terrainPayloads.filter { $0.layer.isOpaque },
            encoder: encoder,
            uniformBuffer: uniformBuffer,
            shadowTexture: shadowTexture,
            shadowSamplerState: shadowSamplerState,
            opaque: true
        )
        solidObjectDrawer(encoder)
        drawTerrainPayloads(
            terrainPayloads.filter { !$0.layer.isOpaque },
            encoder: encoder,
            uniformBuffer: uniformBuffer,
            shadowTexture: shadowTexture,
            shadowSamplerState: shadowSamplerState,
            opaque: false
        )
    }

    func drawShadowPass(
        in encoder: MTLRenderCommandEncoder,
        frame: JungleTerrainFrame,
        shadowFrame: RendererShadowFrame,
        frameResourceIndex: Int
    ) {
        let resourceIndex = normalizedFrameResourceIndex(frameResourceIndex)
        guard
            let terrainPayloads = makeTerrainPayloads(
                for: frame,
                frameResourceIndex: resourceIndex
            ),
            let uniformBuffer = updateUniformBuffer(
                for: frame,
                skyColor: SIMD3<Float>(repeating: 0),
                atmosphereControls: .zero,
                shadowFrame: shadowFrame,
                frameResourceIndex: resourceIndex
            )
        else {
            return
        }

        let opaquePayloads = terrainPayloads.filter { $0.layer.isOpaque }
        guard !opaquePayloads.isEmpty else {
            return
        }

        encoder.setRenderPipelineState(shadowPipelineState)
        encoder.setDepthStencilState(solidDepthStencilState)
        encoder.setCullMode(.back)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)

        for terrainPayload in opaquePayloads {
            encoder.setVertexBuffer(terrainPayload.vertexBuffer, offset: 0, index: 0)
            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: terrainPayload.indexCount,
                indexType: .uint16,
                indexBuffer: terrainPayload.indexBuffer,
                indexBufferOffset: 0
            )
        }
    }

    func skyColor(for frame: JungleTerrainFrame) -> SIMD3<Float> {
        let biome = frame.biomeBlend
        let humidity = frame.ambientWetness
        let shoreline = frame.shorelineSpace
        let horizon = (frame.cameraForward.y + 1.0) * 0.5
        let grasslandSky = SIMD3<Float>(0.52, 0.71, 0.78)
        let jungleSky = SIMD3<Float>(0.18, 0.32, 0.24)
        let beachSky = SIMD3<Float>(0.72, 0.78, 0.82)
        let hazeColor = SIMD3<Float>(0.88, 0.82, 0.70)
        let targetSky: SIMD3<Float>

        switch frame.currentBiome {
        case .grassland:
            targetSky = grasslandSky
        case .jungle:
            targetSky = jungleSky
        case .beach:
            targetSky = beachSky
        }

        var color = mix(grasslandSky, targetSky, t: biome)

        switch frame.currentWeather {
        case .clearBreeze:
            color += SIMD3<Float>(0.01, 0.02, 0.02)
        case .humidCanopy:
            color = mix(color, jungleSky, t: 0.25)
        case .coastalHaze:
            color = mix(color, hazeColor, t: 0.16 + shoreline * 0.28)
        }

        color *= 0.82 + horizon * 0.18 + shoreline * 0.04
        color += SIMD3<Float>(0.03, 0.05, 0.06) * humidity
        color += SIMD3<Float>(0.08, 0.06, 0.03) * shoreline
        return simd_clamp(color, SIMD3<Float>(repeating: 0.0), SIMD3<Float>(repeating: 1.0))
    }

    func atmosphereControls(for frame: JungleTerrainFrame) -> SIMD4<Float> {
        let humidity = frame.ambientWetness
        let shoreline = frame.shorelineSpace
        var controls: SIMD4<Float>

        switch frame.currentBiome {
        case .grassland:
            controls = SIMD4<Float>(0.34, 1.36, 1.12, 0.86)
        case .jungle:
            controls = SIMD4<Float>(0.29, 1.48, 1.18, 0.78)
        case .beach:
            controls = SIMD4<Float>(0.38, 1.30, 1.08, 0.90)
        }

        switch frame.currentWeather {
        case .clearBreeze:
            controls.x += 0.03
            controls.z += 0.02
        case .humidCanopy:
            controls.x -= 0.02
            controls.y += 0.10
            controls.z += 0.03
            controls.w -= 0.05
        case .coastalHaze:
            controls.x -= 0.01
            controls.y += 0.05
            controls.z += 0.02
            controls.w += 0.03
        }

        controls.x = clamp(controls.x - humidity * 0.04 + shoreline * 0.02, min: 0.22, max: 0.48)
        controls.y = clamp(controls.y + humidity * 0.14, min: 1.10, max: 1.75)
        controls.z = clamp(controls.z + humidity * 0.06, min: 1.04, max: 1.26)
        controls.w = clamp(controls.w - humidity * 0.05 + shoreline * 0.04, min: 0.68, max: 0.94)
        return controls
    }

    func lightDirection(for frame: JungleTerrainFrame) -> SIMD3<Float> {
        terrainLightDirection(for: frame)
    }

    private func drawTerrainPayloads(
        _ payloads: [TerrainPayload],
        encoder: MTLRenderCommandEncoder,
        uniformBuffer: MTLBuffer,
        shadowTexture: MTLTexture,
        shadowSamplerState: MTLSamplerState,
        opaque: Bool
    ) {
        guard !payloads.isEmpty else {
            return
        }

        encoder.setCullMode(.back)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(shadowTexture, index: 0)
        encoder.setFragmentSamplerState(shadowSamplerState, index: 0)

        for terrainPayload in payloads {
            if opaque {
                encoder.setRenderPipelineState(solidPipelineState)
                encoder.setDepthStencilState(solidDepthStencilState)
            } else {
                encoder.setRenderPipelineState(alphaPipelineState)
                encoder.setDepthStencilState(alphaDepthStencilState)
            }

            encoder.setVertexBuffer(terrainPayload.vertexBuffer, offset: 0, index: 0)
            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: terrainPayload.indexCount,
                indexType: .uint16,
                indexBuffer: terrainPayload.indexBuffer,
                indexBufferOffset: 0
            )
        }
    }

    private func makeTerrainPayloads(
        for frame: JungleTerrainFrame,
        frameResourceIndex: Int
    ) -> [TerrainPayload]? {
        let patch = frame.terrainPatch
        guard
            patch.sampleSide >= 2,
            patch.samples.count == patch.sampleSide * patch.sampleSide,
            let cachedIndex = indexBuffer(for: patch.sampleSide)
        else {
            return nil
        }

        var payloads: [TerrainPayload] = []
        payloads.reserveCapacity(Self.terrainLayers.count)
        let vertexBufferLength = patch.samples.count * MemoryLayout<TerrainVertex>.stride

        guard ensureVertexBufferCapacity(
            frameResourceIndex: frameResourceIndex,
            requiredLength: vertexBufferLength
        ) else {
            return nil
        }

        for (layerIndex, layer) in Self.terrainLayers.enumerated() {
            let vertices = buildVertices(from: patch, layer: layer, frame: frame)
            guard let vertexBuffer = updateVertexBuffer(
                with: vertices,
                frameResourceIndex: frameResourceIndex,
                layerIndex: layerIndex
            ) else {
                return nil
            }

            payloads.append(
                TerrainPayload(
                    layer: layer,
                    vertexBuffer: vertexBuffer,
                    indexBuffer: cachedIndex.buffer,
                    indexCount: cachedIndex.indexCount
                )
            )
        }

        return payloads
    }

    private func buildVertices(
        from patch: JungleTerrainPatch,
        layer: TerrainLayerDefinition,
        frame: JungleTerrainFrame
    ) -> [TerrainVertex] {
        var vertices: [TerrainVertex] = []
        vertices.reserveCapacity(patch.samples.count)

        for row in 0..<patch.sampleSide {
            for column in 0..<patch.sampleSide {
                let index = row * patch.sampleSide + column
                let sample = patch.samples[index]
                let normal = terrainNormal(row: row, column: column, in: patch)
                let relief = terrainRelief(row: row, column: column, in: patch)
                let layerDensity = density(for: sample, layer: layer.kind, frame: frame)
                let layerColor = vertexColor(
                    for: sample,
                    layer: layer,
                    density: layerDensity,
                    frame: frame
                )
                let color = applyTerrainLighting(
                    to: SIMD3<Float>(layerColor.x, layerColor.y, layerColor.z),
                    normal: normal,
                    relief: relief,
                    sample: sample,
                    layer: layer,
                    frame: frame
                )
                let position = layerPosition(
                    for: sample,
                    layer: layer,
                    density: layerDensity,
                    relief: relief,
                    frame: frame
                )
                let motion = layerMotion(
                    for: sample,
                    layer: layer,
                    density: layerDensity,
                    frame: frame
                )

                vertices.append(
                    TerrainVertex(
                        position: position,
                        color: SIMD4<Float>(color.x, color.y, color.z, layerColor.w),
                        motion: motion
                    )
                )
            }
        }

        return vertices
    }

    private func density(
        for sample: JungleTerrainSample,
        layer: TerrainLayerKind,
        frame: JungleTerrainFrame
    ) -> Float {
        switch layer {
        case .ground:
            return 1.0
        case .understory:
            return simd_clamp(
                sample.groundCover * frame.groundCoverMaterial.alpha +
                    sample.waist * frame.waistMaterial.alpha * 0.26,
                0.0,
                1.0
            )
        case .midstory:
            return simd_clamp(
                sample.waist * frame.waistMaterial.alpha * 0.82 +
                    sample.head * frame.headMaterial.alpha * 0.42,
                0.0,
                1.0
            )
        case .canopy:
            return simd_clamp(
                sample.head * frame.headMaterial.alpha * 0.36 +
                    sample.canopy * frame.canopyMaterial.alpha,
                0.0,
                1.0
            )
        }
    }

    private func vertexColor(
        for sample: JungleTerrainSample,
        layer: TerrainLayerDefinition,
        density: Float,
        frame: JungleTerrainFrame
    ) -> SIMD4<Float> {
        let wetness = sample.wetness * frame.ambientWetness

        switch layer.kind {
        case .ground:
            var color = materialColor(frame.groundMaterial, wetness: wetness)
            color = mix(
                color,
                materialColor(frame.groundCoverMaterial, wetness: wetness),
                t: sample.groundCover * 0.18
            )
            color = mix(
                color,
                materialColor(frame.waistMaterial, wetness: wetness),
                t: sample.waist * 0.08
            )

            let relativeHeight = sample.position.y - frame.cameraFloorHeight
            let elevationLift = max(relativeHeight / max(frame.canopyHeight, 1.0), 0.0) * 0.06
            let surfaceShade = wetness * 0.08 + sample.canopy * 0.10 + sample.head * 0.06
            color *= max(0.38, 1.0 - surfaceShade)
            color += SIMD3<Float>(repeating: elevationLift)
            color = applyContrast(color, amount: 1.04, pivot: 0.42)
            color = simd_clamp(color, SIMD3<Float>(repeating: 0.0), SIMD3<Float>(repeating: 1.0))
            return SIMD4<Float>(color.x, color.y, color.z, 1.0)
        case .understory:
            let lowColor = materialColor(frame.groundCoverMaterial, wetness: wetness)
            let highColor = materialColor(frame.waistMaterial, wetness: wetness)
            let blend = blendFactor(
                primary: sample.waist * frame.waistMaterial.alpha,
                within: density
            )
            var color = mix(lowColor, highColor, t: blend * 0.55)
            color = applyContrast(color, amount: 1.10 + density * 0.18, pivot: 0.41)
            let alpha = layerAlpha(for: sample, layer: layer.kind, density: density)
            return SIMD4<Float>(color.x, color.y, color.z, alpha)
        case .midstory:
            let lowColor = materialColor(frame.waistMaterial, wetness: wetness)
            let highColor = materialColor(frame.headMaterial, wetness: wetness)
            let blend = blendFactor(
                primary: sample.head * frame.headMaterial.alpha,
                within: density
            )
            var color = mix(lowColor, highColor, t: blend * 0.72)
            color = applyContrast(color, amount: 1.14 + density * 0.20, pivot: 0.40)
            let alpha = layerAlpha(for: sample, layer: layer.kind, density: density)
            return SIMD4<Float>(color.x, color.y, color.z, alpha)
        case .canopy:
            let lowColor = materialColor(frame.headMaterial, wetness: wetness)
            let highColor = materialColor(frame.canopyMaterial, wetness: wetness)
            let blend = blendFactor(
                primary: sample.canopy * frame.canopyMaterial.alpha,
                within: density
            )
            var color = mix(lowColor, highColor, t: 0.32 + blend * 0.68)
            color = applyContrast(color, amount: 1.18 + density * 0.22, pivot: 0.39)
            let alpha = layerAlpha(for: sample, layer: layer.kind, density: density)
            return SIMD4<Float>(color.x, color.y, color.z, alpha)
        }
    }

    private func layerMotion(
        for sample: JungleTerrainSample,
        layer: TerrainLayerDefinition,
        density: Float,
        frame: JungleTerrainFrame
    ) -> Float {
        switch layer.kind {
        case .ground:
            return max(
                0.0,
                sample.groundCover * frame.groundCoverMaterial.motion * 0.16 +
                    sample.waist * frame.waistMaterial.motion * 0.05
            )
        case .understory:
            return max(
                0.02,
                density * (
                    sample.groundCover * frame.groundCoverMaterial.motion * 1.08 +
                        sample.waist * frame.waistMaterial.motion * 0.34
                )
            )
        case .midstory:
            return max(
                0.03,
                density * (
                    sample.waist * frame.waistMaterial.motion * 0.92 +
                        sample.head * frame.headMaterial.motion * 0.42
                )
            )
        case .canopy:
            return max(
                0.04,
                density * (
                    sample.head * frame.headMaterial.motion * 0.52 +
                        sample.canopy * frame.canopyMaterial.motion * 0.96
                )
            )
        }
    }

    private func layerPosition(
        for sample: JungleTerrainSample,
        layer: TerrainLayerDefinition,
        density: Float,
        relief: Float,
        frame: JungleTerrainFrame
    ) -> SIMD3<Float> {
        var position = sample.position

        guard !layer.isOpaque else {
            return position
        }

        let forward = horizontalCameraForward(for: frame)
        let right = horizontalCameraRight(for: frame)
        let sampleDirection = normalize(
            SIMD3<Float>(
                position.x - frame.cameraPosition.x,
                0.0,
                position.z - frame.cameraPosition.z
            ),
            fallback: forward
        )
        let lateralAmount = simd_dot(sampleDirection, right)
        let baseHeight = layerBaseHeight(for: layer.kind, frame: frame) * layer.heightScale
        let verticalLift =
            (
                baseHeight * (0.38 + density * 0.62) +
                    max(relief, -0.35) * baseHeight * 0.12
            ) * Self.debugLayerLiftMultiplier
        let depthOffset = -forward * layer.parallaxDepth * (0.24 + density * 0.76)
        let lateralOffset = right * lateralAmount * layer.lateralDrift * (0.20 + density * 0.80)

        position += depthOffset + lateralOffset
        position.y += verticalLift
        return position
    }

    private func layerBaseHeight(
        for layer: TerrainLayerKind,
        frame: JungleTerrainFrame
    ) -> Float {
        switch layer {
        case .ground:
            return 0.0
        case .understory:
            return frame.groundCoverHeight
        case .midstory:
            return frame.waistHeight * 0.78 + frame.headHeight * 0.14
        case .canopy:
            return frame.headHeight * 0.46 + frame.canopyHeight * 0.30
        }
    }

    private func horizontalCameraForward(for frame: JungleTerrainFrame) -> SIMD3<Float> {
        normalize(
            SIMD3<Float>(frame.cameraForward.x, 0.0, frame.cameraForward.z),
            fallback: SIMD3<Float>(0.0, 0.0, 1.0)
        )
    }

    private func horizontalCameraRight(for frame: JungleTerrainFrame) -> SIMD3<Float> {
        normalize(
            SIMD3<Float>(frame.cameraRight.x, 0.0, frame.cameraRight.z),
            fallback: SIMD3<Float>(1.0, 0.0, 0.0)
        )
    }

    private func blendFactor(primary: Float, within total: Float) -> Float {
        guard total > 0.000_1 else {
            return 0.0
        }

        return simd_clamp(primary / total, 0.0, 1.0)
    }

    private func layerAlpha(
        for sample: JungleTerrainSample,
        layer: TerrainLayerKind,
        density: Float
    ) -> Float {
        guard density > 0.000_1 else {
            return 0.0
        }

        let broadNoise = layerNoise(for: sample, layer: layer, seed: 17.0, scale: 0.85)
        let breakupNoise = layerNoise(for: sample, layer: layer, seed: 43.0, scale: 2.4)
        let grainNoise = layerNoise(for: sample, layer: layer, seed: 79.0, scale: 6.4)
        let microNoise = layerNoise(for: sample, layer: layer, seed: 131.0, scale: 12.0)
        let coverageNoise = simd_clamp(
            broadNoise * 0.28 + breakupNoise * 0.30 + grainNoise * 0.24 + microNoise * 0.18,
            0.0,
            1.0
        )
        let coverageThreshold = simd_clamp(
            density * (0.58 + breakupNoise * 0.18 + grainNoise * 0.12 + microNoise * 0.10),
            0.0,
            1.0
        )
        let breakupBoost = simd_clamp(abs(grainNoise - microNoise) * 1.3, 0.0, 1.0)

        guard coverageNoise <= coverageThreshold * (0.90 + breakupBoost * 0.10) else {
            return 0.0
        }

        let opacityNoise = simd_clamp(
            broadNoise * 0.08 + breakupNoise * 0.28 + grainNoise * 0.34 + microNoise * 0.30,
            0.0,
            1.0
        )
        let edgeNoise = simd_clamp(
            (coverageThreshold - coverageNoise) * 4.2 +
                grainNoise * 0.16 +
                microNoise * 0.24 +
                breakupBoost * 0.18,
            0.0,
            1.0
        )
        let minimumAlpha: Float
        let range: Float

        switch layer {
        case .ground:
            return 1.0
        case .understory:
            minimumAlpha = 0.6
            range = 0.3
        case .midstory:
            minimumAlpha = 0.3
            range = 0.3
        case .canopy:
            minimumAlpha = 0.0
            range = 0.3
        }

        return simd_clamp(
            minimumAlpha + opacityNoise * range * (0.58 + edgeNoise * 0.42),
            minimumAlpha,
            minimumAlpha + range
        )
    }

    private func layerNoise(
        for sample: JungleTerrainSample,
        layer: TerrainLayerKind,
        seed: Float,
        scale: Float
    ) -> Float {
        let layerOffset: Float

        switch layer {
        case .ground:
            layerOffset = 0.0
        case .understory:
            layerOffset = 11.0
        case .midstory:
            layerOffset = 23.0
        case .canopy:
            layerOffset = 37.0
        }

        let value =
            sin(
                sample.position.x * (0.173 * scale) + layerOffset * 0.31 + seed
            ) +
            sin(
                sample.position.z * (0.197 * scale) +
                    sample.position.y * (0.123 * scale) +
                    layerOffset * 0.19 +
                    seed * 1.7
            ) +
            sin(
                (sample.position.x + sample.position.z) * (0.091 * scale) +
                    layerOffset * 0.13 +
                    seed * 0.7
            ) +
            sin(
                (sample.position.x - sample.position.z) * (0.141 * scale) +
                    sample.position.y * (0.087 * scale) +
                    layerOffset * 0.11 +
                    seed * 0.5
            )

        return simd_clamp(value * 0.18 + 0.5, 0.0, 1.0)
    }

    private func materialColor(_ channel: JungleMaterialChannel, wetness: Float) -> SIMD3<Float> {
        let base = SIMD3<Float>(channel.red, channel.green, channel.blue)
        let wetBoost = wetness * channel.wetnessResponse
        let tinted = base * (0.82 + wetBoost * 0.26) + SIMD3<Float>(repeating: wetBoost * 0.04)
        return simd_clamp(tinted, SIMD3<Float>(repeating: 0.0), SIMD3<Float>(repeating: 1.0))
    }

    private func terrainNormal(
        row: Int,
        column: Int,
        in patch: JungleTerrainPatch
    ) -> SIMD3<Float> {
        let left = patchSample(row: row, column: column - 1, in: patch).position
        let right = patchSample(row: row, column: column + 1, in: patch).position
        let up = patchSample(row: row - 1, column: column, in: patch).position
        let down = patchSample(row: row + 1, column: column, in: patch).position
        let horizontal = right - left
        let vertical = down - up
        return normalize(
            simd_cross(vertical, horizontal),
            fallback: SIMD3<Float>(0.0, 1.0, 0.0)
        )
    }

    private func terrainRelief(
        row: Int,
        column: Int,
        in patch: JungleTerrainPatch
    ) -> Float {
        let center = patchSample(row: row, column: column, in: patch).position.y
        let left = patchSample(row: row, column: column - 1, in: patch).position.y
        let right = patchSample(row: row, column: column + 1, in: patch).position.y
        let up = patchSample(row: row - 1, column: column, in: patch).position.y
        let down = patchSample(row: row + 1, column: column, in: patch).position.y
        let curvature = center * 4.0 - left - right - up - down
        let spacing = max(patch.spacing, 0.001)
        let normalizedRelief = curvature / max(spacing * 1.4, 0.001)
        return simd_clamp(normalizedRelief, -1.0, 1.0)
    }

    private func applyTerrainLighting(
        to color: SIMD3<Float>,
        normal: SIMD3<Float>,
        relief: Float,
        sample: JungleTerrainSample,
        layer: TerrainLayerDefinition,
        frame: JungleTerrainFrame
    ) -> SIMD3<Float> {
        let lightDirection = terrainLightDirection(for: frame)
        let humidity = frame.ambientWetness
        let vegetationPresence = simd_clamp(
            sample.groundCover * 0.20 +
                sample.waist * 0.34 +
                sample.head * 0.5 +
                sample.canopy * 0.66,
            0.0,
            1.0
        )
        let diffuse = simd_clamp(simd_dot(normal, lightDirection), 0.0, 1.0)
        let wrappedDiffuse = simd_clamp((diffuse + 0.28) / 1.28, 0.0, 1.0)
        let slope = 1.0 - simd_clamp(normal.y, 0.0, 1.0)
        let ridge = simd_clamp(relief, 0.0, 1.0)
        let hollow = simd_clamp(-relief, 0.0, 1.0)
        let translucencyLift: Float = layer.isOpaque ? 0.0 : 0.06 + layer.alphaScale * 0.12
        let shadowWeight: Float = layer.isOpaque ? 1.0 : 0.58
        let lighting = 0.66 + wrappedDiffuse * 0.34 - humidity * 0.03 + translucencyLift
        var lit = color * lighting
        lit += SIMD3<Float>(0.020, 0.024, 0.016) * wrappedDiffuse
        lit -= SIMD3<Float>(0.018, 0.012, 0.010) * slope * shadowWeight
        lit += SIMD3<Float>(0.026, 0.023, 0.017) * ridge * (0.65 + slope * 0.35)
        lit -= SIMD3<Float>(0.030, 0.024, 0.022) * hollow * (0.72 + vegetationPresence * 0.28) * shadowWeight
        let contourContrast =
            1.0 +
            slope * (0.24 + vegetationPresence * 0.10) +
            (ridge + hollow) * 0.22 +
            (layer.isOpaque ? 0.0 : 0.04)
        lit = applyContrast(lit, amount: contourContrast, pivot: 0.40)
        return simd_clamp(lit, SIMD3<Float>(repeating: 0.0), SIMD3<Float>(repeating: 1.0))
    }

    private func terrainLightDirection(for frame: JungleTerrainFrame) -> SIMD3<Float> {
        let shoreline = frame.shorelineSpace
        let baseDirection: SIMD3<Float>

        switch frame.currentBiome {
        case .grassland:
            baseDirection = SIMD3<Float>(0.46, 0.83, -0.31)
        case .jungle:
            baseDirection = SIMD3<Float>(0.32, 0.88, -0.34)
        case .beach:
            baseDirection = SIMD3<Float>(0.52, 0.78, -0.22)
        }

        let weatherOffset: SIMD3<Float>

        switch frame.currentWeather {
        case .clearBreeze:
            weatherOffset = SIMD3<Float>(0.02, 0.02, 0.0)
        case .humidCanopy:
            weatherOffset = SIMD3<Float>(-0.03, 0.05, -0.04)
        case .coastalHaze:
            weatherOffset = SIMD3<Float>(0.01, -0.02, 0.03)
        }

        return normalize(
            baseDirection + weatherOffset + SIMD3<Float>(shoreline * 0.04, 0.0, shoreline * 0.02),
            fallback: SIMD3<Float>(0.0, 1.0, 0.0)
        )
    }

    private func patchSample(
        row: Int,
        column: Int,
        in patch: JungleTerrainPatch
    ) -> JungleTerrainSample {
        let clampedRow = Swift.min(Swift.max(row, 0), patch.sampleSide - 1)
        let clampedColumn = Swift.min(Swift.max(column, 0), patch.sampleSide - 1)
        return patch.samples[clampedRow * patch.sampleSide + clampedColumn]
    }

    private func normalize(
        _ vector: SIMD3<Float>,
        fallback: SIMD3<Float>
    ) -> SIMD3<Float> {
        let lengthSquared = simd_length_squared(vector)
        guard lengthSquared > 0.000_001 else {
            return fallback
        }

        return simd_normalize(vector)
    }

    private func applyContrast(
        _ color: SIMD3<Float>,
        amount: Float,
        pivot: Float
    ) -> SIMD3<Float> {
        let midpoint = SIMD3<Float>(repeating: pivot)
        return simd_clamp(
            (color - midpoint) * max(amount, 0.0) + midpoint,
            SIMD3<Float>(repeating: 0.0),
            SIMD3<Float>(repeating: 1.0)
        )
    }

    private func updateUniformBuffer(
        for frame: JungleTerrainFrame,
        skyColor: SIMD3<Float>,
        atmosphereControls: SIMD4<Float>,
        shadowFrame: RendererShadowFrame,
        frameResourceIndex: Int
    ) -> MTLBuffer? {
        var uniforms = TerrainUniforms(
            viewProjectionMatrix: frame.viewProjectionMatrix,
            shadowViewProjectionMatrix: shadowFrame.viewProjectionMatrix,
            cameraPositionAndTime: SIMD4<Float>(
                frame.cameraPosition.x,
                frame.cameraPosition.y,
                frame.cameraPosition.z,
                Float(frame.simulatedTimeSeconds)
            ),
            skyColorAndVisibility: SIMD4<Float>(
                skyColor.x,
                skyColor.y,
                skyColor.z,
                frame.visibilityDistance
            ),
            atmosphereControls: atmosphereControls,
            shadowParameters: SIMD4<Float>(
                shadowFrame.strength,
                shadowFrame.normalBias,
                shadowFrame.texelSize,
                0
            )
        )

        let uniformBuffer = frameResources[frameResourceIndex].uniformBuffer
        withUnsafeBytes(of: &uniforms) { bytes in
            guard let baseAddress = bytes.baseAddress else {
                return
            }

            uniformBuffer.contents().copyMemory(from: baseAddress, byteCount: bytes.count)
        }

        return uniformBuffer
    }

    private func updateVertexBuffer(
        with vertices: [TerrainVertex],
        frameResourceIndex: Int,
        layerIndex: Int
    ) -> MTLBuffer? {
        guard let vertexBuffer = frameResources[frameResourceIndex].vertexBuffers[layerIndex] else {
            return nil
        }

        let byteCount = vertices.count * MemoryLayout<TerrainVertex>.stride
        guard byteCount <= vertexBuffer.length else {
            return nil
        }

        vertices.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else {
                return
            }

            vertexBuffer.contents().copyMemory(from: baseAddress, byteCount: bytes.count)
        }

        return vertexBuffer
    }

    private func ensureVertexBufferCapacity(
        frameResourceIndex: Int,
        requiredLength: Int
    ) -> Bool {
        guard requiredLength > 0 else {
            return true
        }

        if frameResources[frameResourceIndex].vertexCapacity >= requiredLength {
            return true
        }

        var buffers: [MTLBuffer?] = []
        buffers.reserveCapacity(Self.terrainLayers.count)

        for layerIndex in Self.terrainLayers.indices {
            guard let buffer = metalDevice.makeBuffer(
                length: requiredLength,
                options: .storageModeShared
            ) else {
                return false
            }

            buffer.label = "JungleTerrainVertexBuffer[\(frameResourceIndex):\(layerIndex)]"
            buffers.append(buffer)
        }

        frameResources[frameResourceIndex].vertexBuffers = buffers
        frameResources[frameResourceIndex].vertexCapacity = requiredLength
        return true
    }

    private func normalizedFrameResourceIndex(_ frameResourceIndex: Int) -> Int {
        guard maxFramesInFlight > 0 else {
            return 0
        }

        return ((frameResourceIndex % maxFramesInFlight) + maxFramesInFlight) % maxFramesInFlight
    }

    private func indexBuffer(for sampleSide: Int) -> (buffer: MTLBuffer, indexCount: Int)? {
        if let cached = cachedIndexBuffers[sampleSide] {
            return cached
        }

        guard sampleSide >= 2 else {
            return nil
        }

        var indices: [UInt16] = []
        indices.reserveCapacity((sampleSide - 1) * (sampleSide - 1) * 6)

        for row in 0..<(sampleSide - 1) {
            for column in 0..<(sampleSide - 1) {
                let topLeft = UInt16(row * sampleSide + column)
                let topRight = UInt16(row * sampleSide + column + 1)
                let bottomLeft = UInt16((row + 1) * sampleSide + column)
                let bottomRight = UInt16((row + 1) * sampleSide + column + 1)

                indices.append(topLeft)
                indices.append(bottomLeft)
                indices.append(topRight)
                indices.append(topRight)
                indices.append(bottomLeft)
                indices.append(bottomRight)
            }
        }

        guard let buffer = indices.withUnsafeBytes({ bytes -> MTLBuffer? in
            guard let baseAddress = bytes.baseAddress else {
                return nil
            }

            return metalDevice.makeBuffer(
                bytes: baseAddress,
                length: bytes.count,
                options: .storageModeShared
            )
        }) else {
            return nil
        }

        let cached = (buffer: buffer, indexCount: indices.count)
        cachedIndexBuffers[sampleSide] = cached
        return cached
    }

    private func mix(
        _ start: SIMD3<Float>,
        _ end: SIMD3<Float>,
        t: Float
    ) -> SIMD3<Float> {
        start + (end - start) * simd_clamp(t, 0.0, 1.0)
    }

    private func clamp(_ value: Float, min minimum: Float, max maximum: Float) -> Float {
        Swift.min(Swift.max(value, minimum), maximum)
    }

    private static func makePipelineState(
        device: MTLDevice,
        vertexFunction: MTLFunction,
        fragmentFunction: MTLFunction,
        vertexDescriptor: MTLVertexDescriptor,
        colorPixelFormat: MTLPixelFormat,
        depthPixelFormat: MTLPixelFormat,
        blendingEnabled: Bool
    ) -> MTLRenderPipelineState? {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = blendingEnabled
            ? "JungleTerrainAlphaPipeline"
            : "JungleTerrainSolidPipeline"
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.depthAttachmentPixelFormat = depthPixelFormat

        if blendingEnabled {
            let attachment = descriptor.colorAttachments[0]
            attachment?.isBlendingEnabled = true
            attachment?.rgbBlendOperation = .add
            attachment?.alphaBlendOperation = .add
            attachment?.sourceRGBBlendFactor = .sourceAlpha
            attachment?.sourceAlphaBlendFactor = .one
            attachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha
            attachment?.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private static func makeShadowPipelineState(
        device: MTLDevice,
        vertexFunction: MTLFunction,
        vertexDescriptor: MTLVertexDescriptor,
        depthPixelFormat: MTLPixelFormat
    ) -> MTLRenderPipelineState? {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "JungleTerrainShadowPipeline"
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = nil
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.depthAttachmentPixelFormat = depthPixelFormat
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private static func makeDepthStencilState(
        device: MTLDevice,
        writeEnabled: Bool,
        compareFunction: MTLCompareFunction
    ) -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = writeEnabled
        descriptor.depthCompareFunction = compareFunction
        return device.makeDepthStencilState(descriptor: descriptor)
    }
}
