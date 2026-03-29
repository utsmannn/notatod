import SwiftUI

// MARK: - ScrollView Transparent Track Modifier

struct TransparentScrollTrackModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ScrollViewTrackTransparentizer())
    }
}

// Custom scroller with transparent track
class TransparentScroller: NSScroller {
    override func draw(_ dirtyRect: NSRect) {
        // Only draw the knob, not the track/slot
        drawKnob()
    }

    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        // Don't draw the slot/track at all
    }
}

// Helper view that finds and modifies the NSScrollView
struct ScrollViewTrackTransparentizer: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.isHidden = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let scrollView = nsView.findParentScrollView() else { return }

            scrollView.drawsBackground = false
            scrollView.scrollerStyle = .overlay
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true

            if let textView = scrollView.documentView as? NSTextView {
                textView.drawsBackground = false
            }

            if !(scrollView.verticalScroller is TransparentScroller) {
                let newScroller = TransparentScroller()
                newScroller.controlSize = .small
                scrollView.verticalScroller = newScroller
            }
        }
    }
}

// Extension to find NSScrollView in view hierarchy
extension NSView {
    func findParentScrollView() -> NSScrollView? {
        var current: NSView? = self
        while let view = current {
            if let scrollView = view as? NSScrollView {
                return scrollView
            }
            current = view.superview
        }
        return nil
    }
}

// MARK: - View Extension

extension View {
    func transparentScrollTrack() -> some View {
        modifier(TransparentScrollTrackModifier())
    }
}
