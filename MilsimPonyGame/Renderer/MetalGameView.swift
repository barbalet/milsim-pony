import MetalKit
import SwiftUI

protocol InputTrackingMetalViewDelegate: AnyObject {
    func inputView(_ view: InputTrackingMetalView, keyDidChange keyCode: UInt16, isPressed: Bool)
    func inputView(_ view: InputTrackingMetalView, mouseDidMove deltaX: CGFloat, deltaY: CGFloat)
    func inputViewDidBecomeActive(_ view: InputTrackingMetalView)
}

struct MetalGameView: NSViewRepresentable {
    @ObservedObject var session: GameSession

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    func makeNSView(context: Context) -> InputTrackingMetalView {
        let metalView = InputTrackingMetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        metalView.clearColor = MTLClearColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1)
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false
        metalView.preferredFramesPerSecond = 60
        metalView.inputDelegate = context.coordinator

        if let renderer = GameRenderer(view: metalView, session: session) {
            context.coordinator.renderer = renderer
            metalView.delegate = renderer
            session.noteRendererReady(deviceName: renderer.deviceName)
        } else {
            session.noteRendererUnavailable()
        }

        return metalView
    }

    func updateNSView(_ nsView: InputTrackingMetalView, context: Context) {
        context.coordinator.session = session
    }

    final class Coordinator: NSObject, InputTrackingMetalViewDelegate {
        var session: GameSession
        var renderer: GameRenderer?

        init(session: GameSession) {
            self.session = session
        }

        func inputView(_ view: InputTrackingMetalView, keyDidChange keyCode: UInt16, isPressed: Bool) {
            session.handleKey(keyCode, isPressed: isPressed)
        }

        func inputView(_ view: InputTrackingMetalView, mouseDidMove deltaX: CGFloat, deltaY: CGFloat) {
            session.handleMouseDelta(x: deltaX, y: deltaY)
        }

        func inputViewDidBecomeActive(_ view: InputTrackingMetalView) {
            session.noteViewActivation()
        }
    }
}

final class InputTrackingMetalView: MTKView {
    weak var inputDelegate: InputTrackingMetalViewDelegate?
    private var localTrackingArea: NSTrackingArea?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
        window?.makeFirstResponder(self)
        inputDelegate?.inputViewDidBecomeActive(self)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let localTrackingArea {
            removeTrackingArea(localTrackingArea)
        }

        let options: NSTrackingArea.Options = [
            .activeInKeyWindow,
            .inVisibleRect,
            .mouseMoved,
            .mouseEnteredAndExited,
        ]

        localTrackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        if let localTrackingArea {
            addTrackingArea(localTrackingArea)
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        inputDelegate?.inputView(self, keyDidChange: event.keyCode, isPressed: true)
    }

    override func keyUp(with event: NSEvent) {
        inputDelegate?.inputView(self, keyDidChange: event.keyCode, isPressed: false)
    }

    override func flagsChanged(with event: NSEvent) {
        guard event.keyCode == 56 || event.keyCode == 60 else {
            super.flagsChanged(with: event)
            return
        }

        let isPressed = event.modifierFlags.contains(.shift)
        inputDelegate?.inputView(self, keyDidChange: event.keyCode, isPressed: isPressed)
    }

    override func mouseMoved(with event: NSEvent) {
        inputDelegate?.inputView(self, mouseDidMove: event.deltaX, deltaY: event.deltaY)
    }

    override func mouseDragged(with event: NSEvent) {
        inputDelegate?.inputView(self, mouseDidMove: event.deltaX, deltaY: event.deltaY)
    }

    override func rightMouseDragged(with event: NSEvent) {
        inputDelegate?.inputView(self, mouseDidMove: event.deltaX, deltaY: event.deltaY)
    }
}
