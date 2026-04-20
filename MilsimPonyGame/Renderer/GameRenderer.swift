import Foundation
import MetalKit
import QuartzCore
import simd

final class GameRenderer: NSObject, MTKViewDelegate {
    let deviceName: String

    private let commandQueue: MTLCommandQueue
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

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Bootstrap Scene Pipeline"
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "bootstrapVertexMain")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "bootstrapFragmentMain")
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat

        do {
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

        GameCoreTick(deltaTime)
        let snapshot = GameCoreGetSnapshot()

        if now - lastOverlayUpdateTime > 0.12 {
            lastOverlayUpdateTime = now
            DispatchQueue.main.async { [weak self] in
                self?.session?.accept(snapshot: snapshot, drawableSize: view.drawableSize)
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
                    drawableCount: self?.scene.drawables.count ?? 0
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

        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.03 + strafeTint,
            green: 0.04 + forwardTint,
            blue: 0.08 + pulse,
            alpha: 1
        )
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        encoder.label = "Bootstrap Scene Pass"
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

        let cameraPosition = SIMD3<Float>(snapshot.cameraX, snapshot.cameraY, snapshot.cameraZ)
        let forward = RenderMath.forwardVector(yawDegrees: snapshot.yawDegrees, pitchDegrees: snapshot.pitchDegrees)
        let viewMatrix = simd_float4x4.lookAt(
            eye: cameraPosition,
            center: cameraPosition + forward,
            up: SIMD3<Float>(0, 1, 0)
        )

        let viewProjectionMatrix = projectionMatrix * viewMatrix
        let lightDirection = simd_normalize(SIMD3<Float>(-0.6, -1.0, -0.45))

        for drawableItem in scene.drawables {
            var uniforms = SceneUniforms(
                viewProjectionMatrix: viewProjectionMatrix,
                modelMatrix: drawableItem.modelMatrix,
                lightDirection: lightDirection,
                ambientIntensity: 0.32
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
