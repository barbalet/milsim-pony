import MetalKit
import SwiftUI

protocol InputTrackingMetalViewDelegate: AnyObject {
    func inputViewCanCaptureFocus(_ view: InputTrackingMetalView) -> Bool
    func inputView(
        _ view: InputTrackingMetalView,
        keyDidChange keyCode: UInt16,
        characters: String?,
        isPressed: Bool,
        isRepeat: Bool
    )
    func inputView(_ view: InputTrackingMetalView, mouseDidMove deltaX: CGFloat, deltaY: CGFloat)
    func inputViewDidRequestPrimaryFire(_ view: InputTrackingMetalView)
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
            DispatchQueue.main.async {
                session.noteRendererReady(deviceName: renderer.deviceName)
            }
        } else {
            DispatchQueue.main.async {
                session.noteRendererUnavailable()
            }
        }

        return metalView
    }

    func updateNSView(_ nsView: InputTrackingMetalView, context: Context) {
        context.coordinator.session = session
        nsView.inputDelegate = context.coordinator
        nsView.ensureInputPipelineInstalled()
        context.coordinator.syncInputFocusRequest(with: nsView, session: session)
    }

    final class Coordinator: NSObject, InputTrackingMetalViewDelegate {
        var session: GameSession
        var renderer: GameRenderer?
        private var handledInputFocusRequestID = 0

        init(session: GameSession) {
            self.session = session
            self.handledInputFocusRequestID = session.inputFocusRequestID
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

        func inputViewDidRequestPrimaryFire(_ view: InputTrackingMetalView) {
            session.handlePrimaryFireRequest()
        }

        func inputViewDidBecomeActive(_ view: InputTrackingMetalView) {
            session.noteViewActivation()
        }

        func inputViewCanCaptureFocus(_ view: InputTrackingMetalView) -> Bool {
            session.allowsGameplayInputFocusCapture
        }

        func syncInputFocusRequest(with view: InputTrackingMetalView, session: GameSession) {
            guard handledInputFocusRequestID != session.inputFocusRequestID else {
                return
            }

            handledInputFocusRequestID = session.inputFocusRequestID
            view.captureInputFocus()
        }
    }
}

final class InputTrackingMetalView: MTKView {
    weak var inputDelegate: InputTrackingMetalViewDelegate?
    private var localTrackingArea: NSTrackingArea?
    private var keyWindowObserver: NSObjectProtocol?
    private var resignKeyWindowObserver: NSObjectProtocol?
    private var windowDidUpdateObserver: NSObjectProtocol?
    private var appDidBecomeActiveObserver: NSObjectProtocol?
    private weak var observedWindow: NSWindow?
    private var lastMouseLocationInWindow: CGPoint?
    private var focusRetryGeneration = 0

    deinit {
        GameplayInputRouter.shared.detach(self)
        removeWindowObservers()
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if observedWindow !== newWindow {
            removeWindowObservers()
        }
        super.viewWillMove(toWindow: newWindow)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        ensureInputPipelineInstalled()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let localTrackingArea {
            removeTrackingArea(localTrackingArea)
        }

        let options: NSTrackingArea.Options = [
            .activeAlways,
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
        rememberMouseLocation(from: event)
        captureInputFocus(retryIfNeeded: true)
        if hasInputFocus {
            inputDelegate?.inputViewDidRequestPrimaryFire(self)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        captureInputFocus(retryIfNeeded: false)
        super.mouseEntered(with: event)
    }

    func ensureInputPipelineInstalled() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.ensureInputPipelineInstalled()
            }
            return
        }

        let didAttachWindow = window != nil && observedWindow !== window
        window?.acceptsMouseMovedEvents = true
        GameplayInputRouter.shared.attach(self)
        installWindowObserversIfNeeded()

        guard window != nil else {
            return
        }

        if didAttachWindow || !hasInputFocus {
            captureInputFocus()
            scheduleFocusCaptureRetries()
        }
    }

    func captureInputFocus() {
        captureInputFocus(retryIfNeeded: true)
    }

    private var hasInputFocus: Bool {
        window?.isKeyWindow == true && window?.firstResponder === self
    }

    private func captureInputFocus(retryIfNeeded: Bool) {
        guard inputDelegate?.inputViewCanCaptureFocus(self) ?? true else {
            return
        }

        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.captureInputFocus(retryIfNeeded: retryIfNeeded)
            }
            return
        }

        guard let window else {
            return
        }

        guard window.isVisible else {
            return
        }

        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
        }

        let alreadyFocused = window.isKeyWindow && window.firstResponder === self
        if !window.isKeyWindow {
            window.makeKeyAndOrderFront(nil)
        }
        window.acceptsMouseMovedEvents = true
        window.makeFirstResponder(self)

        let hasInputFocus = window.isKeyWindow && window.firstResponder === self
        if hasInputFocus {
            if !alreadyFocused {
                inputDelegate?.inputViewDidBecomeActive(self)
            }
        } else if retryIfNeeded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.captureInputFocus(retryIfNeeded: false)
            }
        }
    }

    private func scheduleFocusCaptureRetries() {
        focusRetryGeneration &+= 1
        let generation = focusRetryGeneration
        for delay in [0.02, 0.05, 0.12, 0.25, 0.50, 0.90] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.focusRetryGeneration == generation else {
                    return
                }

                self.captureInputFocus(retryIfNeeded: true)
            }
        }
    }

    private func installWindowObserversIfNeeded() {
        guard let window, observedWindow !== window else {
            return
        }

        removeWindowObservers()
        observedWindow = window
        keyWindowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self, self.window != nil, NSApp.isActive else {
                return
            }

            if notification.object as? NSWindow === self.window {
                self.captureInputFocus()
            } else {
                self.scheduleFocusCaptureRetries()
            }
        }
        resignKeyWindowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleFocusCaptureRetries()
        }
        windowDidUpdateObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didUpdateNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            guard let self else {
                return
            }

            self.window?.acceptsMouseMovedEvents = true
            if self.window?.isKeyWindow == true {
                self.captureInputFocus(retryIfNeeded: false)
            }
        }
        appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.window?.isKeyWindow == true else {
                return
            }

            self.captureInputFocus()
        }
    }

    private func removeWindowObservers() {
        if let keyWindowObserver {
            NotificationCenter.default.removeObserver(keyWindowObserver)
            self.keyWindowObserver = nil
        }

        if let resignKeyWindowObserver {
            NotificationCenter.default.removeObserver(resignKeyWindowObserver)
            self.resignKeyWindowObserver = nil
        }

        if let appDidBecomeActiveObserver {
            NotificationCenter.default.removeObserver(appDidBecomeActiveObserver)
            self.appDidBecomeActiveObserver = nil
        }

        if let windowDidUpdateObserver {
            NotificationCenter.default.removeObserver(windowDidUpdateObserver)
            self.windowDidUpdateObserver = nil
        }

        observedWindow = nil
    }

    override func keyDown(with event: NSEvent) {
        captureInputFocus(retryIfNeeded: false)
        if dispatchInputEventIfHandled(event) {
            return
        }

        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        captureInputFocus(retryIfNeeded: false)
        if dispatchInputEventIfHandled(event) {
            return
        }

        super.keyUp(with: event)
    }

    override func flagsChanged(with event: NSEvent) {
        captureInputFocus(retryIfNeeded: false)
        if dispatchInputEventIfHandled(event) {
            return
        }

        guard event.keyCode == 56 || event.keyCode == 60 else {
            super.flagsChanged(with: event)
            return
        }
    }

    override func mouseMoved(with event: NSEvent) {
        captureInputFocus(retryIfNeeded: false)
        dispatchMouseEventIfHandled(event)
    }

    override func mouseDragged(with event: NSEvent) {
        captureInputFocus(retryIfNeeded: false)
        dispatchMouseEventIfHandled(event)
    }

    override func rightMouseDragged(with event: NSEvent) {
        captureInputFocus(retryIfNeeded: false)
        dispatchMouseEventIfHandled(event)
    }

    fileprivate func routeLocalMouseEvent(_ event: NSEvent) -> Bool {
        guard shouldHandleLocalEvent(event), isEventInsideView(event) else {
            return false
        }

        if event.type == .leftMouseDown {
            rememberMouseLocation(from: event)
            captureInputFocus(retryIfNeeded: true)
            inputDelegate?.inputViewDidRequestPrimaryFire(self)
            return true
        }

        captureInputFocus(retryIfNeeded: false)
        dispatchMouseEventIfHandled(event)
        return true
    }

    fileprivate func routeLocalKeyEvent(_ event: NSEvent) -> Bool {
        guard shouldHandleLocalKeyEvent(event) else {
            return false
        }

        captureInputFocus(retryIfNeeded: true)
        if dispatchInputEventIfHandled(event) {
            return true
        }

        return false
    }

    private func shouldHandleLocalEvent(_ event: NSEvent) -> Bool {
        guard let window, event.window === window else {
            return false
        }

        return window.isVisible
    }

    private func shouldHandleLocalKeyEvent(_ event: NSEvent) -> Bool {
        guard NSApp.isActive, event.modifierFlags.intersection([.command, .option, .control]).isEmpty else {
            return false
        }

        if event.window?.firstResponder is NSTextView {
            return false
        }

        return InputBindings.command(
            for: event.keyCode,
            characters: event.charactersIgnoringModifiers
        ) != nil
    }

    private func isEventInsideView(_ event: NSEvent) -> Bool {
        guard event.window === window else {
            return false
        }

        let point = convert(event.locationInWindow, from: nil)
        return bounds.contains(point)
    }

    @discardableResult
    private func dispatchMouseEventIfHandled(_ event: NSEvent) -> Bool {
        let locationDelta = mouseLocationDelta(from: event)
        let deltaX = event.deltaX != 0 ? event.deltaX : locationDelta.x
        let deltaY = event.deltaY != 0 ? event.deltaY : locationDelta.y
        rememberMouseLocation(from: event)

        guard deltaX != 0 || deltaY != 0 else {
            return false
        }

        inputDelegate?.inputView(self, mouseDidMove: deltaX, deltaY: deltaY)
        return true
    }

    private func rememberMouseLocation(from event: NSEvent) {
        guard event.window === window else {
            return
        }

        lastMouseLocationInWindow = event.locationInWindow
    }

    private func mouseLocationDelta(from event: NSEvent) -> CGPoint {
        guard event.window === window, let lastMouseLocationInWindow else {
            return .zero
        }

        let location = event.locationInWindow
        return CGPoint(
            x: location.x - lastMouseLocationInWindow.x,
            y: location.y - lastMouseLocationInWindow.y
        )
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
            guard event.modifierFlags.intersection([.command, .option, .control]).isEmpty else {
                return false
            }

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

private final class GameplayInputRouter {
    static let shared = GameplayInputRouter()

    private weak var inputView: InputTrackingMetalView?
    private var localKeyMonitor: Any?
    private var localMouseMonitor: Any?

    private init() {}

    deinit {
        uninstallMonitors()
    }

    func attach(_ view: InputTrackingMetalView) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view else {
                    return
                }

                self.attach(view)
            }
            return
        }

        inputView = view
        installMonitorsIfNeeded()
    }

    func detach(_ view: InputTrackingMetalView) {
        guard inputView === view else {
            return
        }

        inputView = nil
    }

    private func installMonitorsIfNeeded() {
        if localKeyMonitor == nil {
            localKeyMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.keyDown, .keyUp, .flagsChanged]
            ) { [weak self] event in
                guard let self, let inputView = self.inputView else {
                    return event
                }

                return inputView.routeLocalKeyEvent(event) ? nil : event
            }
        }

        if localMouseMonitor == nil {
            localMouseMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.leftMouseDown, .mouseMoved, .leftMouseDragged, .rightMouseDragged]
            ) { [weak self] event in
                guard let self, let inputView = self.inputView else {
                    return event
                }

                return inputView.routeLocalMouseEvent(event) ? nil : event
            }
        }
    }

    private func uninstallMonitors() {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }

        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
    }
}
