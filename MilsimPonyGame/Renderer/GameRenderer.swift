import Foundation
import MetalKit
import QuartzCore
import simd

final class GameRenderer: NSObject, MTKViewDelegate {
    let deviceName: String

    private let commandQueue: MTLCommandQueue
    private let skyPipelineState: MTLRenderPipelineState
    private let renderPipelineState: MTLRenderPipelineState
    private let depthStencilState: MTLDepthStencilState
    private let scene: BootstrapScene
    private weak var session: GameSession?
    private var lastFrameTimestamp: CFTimeInterval?
    private var lastOverlayUpdateTime: CFTimeInterval = 0
    private var lastPerformanceUpdateTime: CFTimeInterval = 0
    private var accumulatedFrameTime: Double = 0
    private var accumulatedFrameCount = 0

    init?(view: MTKView, session: GameSession) {
        guard
            let device = view.device,
            let commandQueue = device.makeCommandQueue(),
            let library = device.makeDefaultLibrary()
        else {
            return nil
        }

        self.deviceName = device.name
        self.commandQueue = commandQueue
        self.session = session
        self.scene = BootstrapScene(
            device: device,
            assetRoot: session.assetRootPath,
            worldDataRoot: session.worldDataRootPath,
            worldManifestPath: session.worldManifestPath
        )

        let skyPipelineDescriptor = MTLRenderPipelineDescriptor()
        skyPipelineDescriptor.label = "Bootstrap Sky Pipeline"
        skyPipelineDescriptor.vertexFunction = library.makeFunction(name: "skyVertexMain")
        skyPipelineDescriptor.fragmentFunction = library.makeFunction(name: "skyFragmentMain")
        skyPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        skyPipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        skyPipelineDescriptor.rasterSampleCount = view.sampleCount

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Bootstrap Scene Pipeline"
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "bootstrapVertexMain")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "bootstrapFragmentMain")
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.rasterSampleCount = view.sampleCount
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat

        do {
            skyPipelineState = try device.makeRenderPipelineState(descriptor: skyPipelineDescriptor)
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("[Renderer] Failed to create pipeline state: \(error)")
            return nil
        }

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true

        guard let depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor) else {
            return nil
        }
        self.depthStencilState = depthStencilState

        super.init()

        scene.configureGameCore()
        let spawn = scene.debugInfo.spawn.positionVector
        GameCoreConfigureSpawn(
            spawn.x,
            spawn.y,
            spawn.z,
            scene.debugInfo.spawn.yawDegrees,
            scene.debugInfo.spawn.pitchDegrees
        )
        session.noteSceneReady(
            label: scene.debugInfo.sceneName,
            summary: scene.debugInfo.summary,
            details: scene.debugInfo.details
        )
        session.noteOverlayTitle(scene.debugInfo.cycleLabel)
        print("[Renderer] Metal bootstrap ready on \(device.name) with \(scene.debugInfo.summary)")
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
        let forwardVector = RenderMath.forwardVector(yawDegrees: snapshot.yawDegrees, pitchDegrees: snapshot.pitchDegrees)
        let visibilityState = scene.visibilityState(for: cameraPosition, forwardVector: forwardVector)
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
            DispatchQueue.main.async { [weak self] in
                self?.session?.accept(snapshot: snapshot, drawableSize: view.drawableSize)
                self?.session?.noteBriefingState(
                    summary: briefingState.summary,
                    details: briefingState.details
                )
                self?.session?.noteRouteState(
                    summary: routeState.summary,
                    details: routeState.details
                )
                self?.session?.noteEvasionState(
                    summary: evasionState.summary,
                    details: evasionState.details
                )
                self?.session?.noteStreamingState(
                    summary: streamingState.summary,
                    details: streamingState.details
                )
            }
        }

        if now - lastPerformanceUpdateTime > 0.45, accumulatedFrameCount > 0 {
            let averageFrameTime = accumulatedFrameTime / Double(accumulatedFrameCount)
            let framesPerSecond = averageFrameTime > 0 ? (1 / averageFrameTime) : 0
            lastPerformanceUpdateTime = now
            accumulatedFrameTime = 0
            accumulatedFrameCount = 0

            DispatchQueue.main.async { [weak self] in
                self?.session?.noteFrameTiming(
                    milliseconds: averageFrameTime * 1000,
                    framesPerSecond: framesPerSecond,
                    drawableCount: visibilityState.drawables.count
                )
            }
        }

        guard
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }

        let strafeTint = Double(snapshot.strafeIntent) * 0.015
        let forwardTint = Double(snapshot.forwardIntent) * 0.015
        let pulse = sin(snapshot.elapsedSeconds * 0.85) * 0.015
        let suspicionTint = Double(min(max(snapshot.suspicionLevel, 0), 1))
        let failurePulse = snapshot.routeFailed ? (0.08 + (sin(snapshot.elapsedSeconds * 7.5) * 0.04)) : 0

        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: Double(scene.environment.skyHorizonColor.x) + strafeTint + (suspicionTint * 0.14) + failurePulse,
            green: Double(scene.environment.skyHorizonColor.y) + forwardTint - (suspicionTint * 0.08),
            blue: Double(scene.environment.skyZenithColor.z) + pulse - (suspicionTint * 0.06),
            alpha: 1
        )
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        encoder.label = "Bootstrap Scene Pass"
        var skyUniforms = SkyUniforms(
            horizonColor: scene.environment.skyHorizonColor,
            zenithColor: scene.environment.skyZenithColor,
            sunColor: SIMD4<Float>(scene.environment.sunColor.x, scene.environment.sunColor.y, scene.environment.sunColor.z, 1),
            skyParameters: SIMD4<Float>(scene.environment.hazeStrength, 0, 0, 0)
        )
        encoder.setRenderPipelineState(skyPipelineState)
        encoder.setCullMode(.none)
        encoder.setFragmentBytes(&skyUniforms, length: MemoryLayout<SkyUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setCullMode(.back)
        encoder.setFrontFacing(.counterClockwise)

        let aspectRatio = max(Float(view.drawableSize.width / max(view.drawableSize.height, 1)), 0.1)
        let projectionMatrix = simd_float4x4.perspective(
            fieldOfViewY: 60.0 * (.pi / 180.0),
            aspectRatio: aspectRatio,
            nearZ: 0.1,
            farZ: 100.0
        )

        let viewMatrix = simd_float4x4.lookAt(
            eye: cameraPosition,
            center: cameraPosition + forwardVector,
            up: SIMD3<Float>(0, 1, 0)
        )

        let viewProjectionMatrix = projectionMatrix * viewMatrix
        let lightDirection = simd_normalize(scene.environment.sunDirection)

        for drawableItem in visibilityState.drawables {
            var uniforms = SceneUniforms(
                viewProjectionMatrix: viewProjectionMatrix,
                modelMatrix: drawableItem.modelMatrix,
                lightDirection: SIMD4<Float>(lightDirection.x, lightDirection.y, lightDirection.z, 0),
                sunColor: SIMD4<Float>(scene.environment.sunColor.x, scene.environment.sunColor.y, scene.environment.sunColor.z, 1),
                cameraPosition: SIMD4<Float>(cameraPosition.x, cameraPosition.y, cameraPosition.z, 1),
                fogColor: scene.environment.fogColor,
                lightingParameters: SIMD4<Float>(
                    scene.environment.ambientIntensity,
                    scene.environment.diffuseIntensity,
                    scene.environment.fogNear,
                    scene.environment.fogFar
                ),
                atmosphereParameters: SIMD4<Float>(scene.environment.hazeStrength, 0, 0, 0)
            )

            encoder.setVertexBuffer(drawableItem.vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: drawableItem.vertexCount)
        }

        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
