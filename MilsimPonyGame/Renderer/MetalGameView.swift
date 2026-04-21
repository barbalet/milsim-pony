import MetalKit
import SwiftUI

protocol InputTrackingMetalViewDelegate: AnyObject {
    func inputView(
        _ view: InputTrackingMetalView,
        keyDidChange keyCode: UInt16,
        characters: String?,
        isPressed: Bool,
        isRepeat: Bool
    )
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

        func inputView(
            _ view: InputTrackingMetalView,
            keyDidChange keyCode: UInt16,
            characters: String?,
            isPressed: Bool,
            isRepeat: Bool
        ) {
            session.handleKey(
                keyCode,
                characters: characters,
                isPressed: isPressed,
                isRepeat: isRepeat
            )
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
    private var localKeyMonitor: Any?

    deinit {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
        window?.makeFirstResponder(self)
        installLocalKeyMonitorIfNeeded()
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
        if localKeyMonitor == nil, dispatchInputEventIfHandled(event) {
            return
        }

        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        if localKeyMonitor == nil, dispatchInputEventIfHandled(event) {
            return
        }

        super.keyUp(with: event)
    }

    override func flagsChanged(with event: NSEvent) {
        if localKeyMonitor == nil, dispatchInputEventIfHandled(event) {
            return
        }

        guard event.keyCode == 56 || event.keyCode == 60 else {
            super.flagsChanged(with: event)
            return
        }
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

    private func installLocalKeyMonitorIfNeeded() {
        guard localKeyMonitor == nil else {
            return
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .keyUp, .flagsChanged]
        ) { [weak self] event in
            guard let self else {
                return event
            }

            if self.dispatchInputEventIfHandled(event) {
                return nil
            }

            return event
        }
    }

    private func dispatchInputEventIfHandled(_ event: NSEvent) -> Bool {
        switch event.type {
        case .flagsChanged:
            guard event.keyCode == 56 || event.keyCode == 60 else {
                return false
            }

            let isPressed = event.modifierFlags.contains(.shift)
            inputDelegate?.inputView(
                self,
                keyDidChange: event.keyCode,
                characters: nil,
                isPressed: isPressed,
                isRepeat: false
            )
            return true

        case .keyDown, .keyUp:
            let characters = event.charactersIgnoringModifiers
            guard InputBindings.command(for: event.keyCode, characters: characters) != nil else {
                return false
            }

            inputDelegate?.inputView(
                self,
                keyDidChange: event.keyCode,
                characters: characters,
                isPressed: event.type == .keyDown,
                isRepeat: event.type == .keyDown ? event.isARepeat : false
            )
            return true

        default:
            return false
        }
    }
}
