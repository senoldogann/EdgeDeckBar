import AppKit
import Foundation

private final class EdgeActivationTrackingView: NSView {
    private let onReveal: () -> Void
    private var trackingArea: NSTrackingArea?

    init(onReveal: @escaping () -> Void) {
        self.onReveal = onReveal
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        onReveal()
    }
}

@MainActor
public final class EdgePanelController {
    public let dockPanel: NSPanel
    public let activationPanel: NSPanel
    private let onReveal: () -> Void

    public init(onReveal: @escaping () -> Void) {
        self.onReveal = onReveal

        let collectionBehavior = edgePanelCollectionBehavior()

        let dock = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        dock.isFloatingPanel = true
        dock.level = .floating
        dock.collectionBehavior = collectionBehavior
        dock.isOpaque = false
        dock.backgroundColor = .clear
        dock.hasShadow = false
        dock.hidesOnDeactivate = false
        dock.acceptsMouseMovedEvents = true
        self.dockPanel = dock

        let activation = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        activation.isFloatingPanel = true
        activation.level = .floating
        activation.collectionBehavior = collectionBehavior
        activation.isOpaque = false
        activation.backgroundColor = .clear
        activation.hasShadow = false
        activation.hidesOnDeactivate = false
        activation.acceptsMouseMovedEvents = true

        let trackingView = EdgeActivationTrackingView(onReveal: onReveal)
        activation.contentView = trackingView
        self.activationPanel = activation
    }

    /// Çerçeve değişmediyse pencereyi yeniden boyutlandırıp senkron olarak yeniden çizmez; her dispatch'te çağrılır.
    public func show(frame: CGRect) {
        if dockPanel.frame != frame {
            dockPanel.setFrame(frame, display: true, animate: false)
        }
        if !dockPanel.isVisible {
            dockPanel.orderFrontRegardless()
        }
    }

    public func hide() {
        dockPanel.orderOut(nil)
    }

    public func reposition(frame: CGRect) {
        dockPanel.setFrame(frame, display: true, animate: false)
    }

    public func setAutoHide(enabled: Bool, activationFrame: CGRect) {
        if enabled {
            if activationPanel.frame != activationFrame {
                activationPanel.setFrame(activationFrame, display: true, animate: false)
            }
            if !activationPanel.isVisible {
                activationPanel.orderFrontRegardless()
            }
        } else if activationPanel.isVisible {
            activationPanel.orderOut(nil)
        }
    }

    public func setContentView(_ view: NSView) {
        dockPanel.contentView = view
    }
}
