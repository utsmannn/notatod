import SwiftUI

@available(macOS 10.15, *)
extension KeyboardShortcuts {
	/**
	A SwiftUI `View` that lets the user record a keyboard shortcut.

	You would usually put this in your preferences window.

	It automatically prevents choosing a keyboard shortcut that is already taken by the system or by the app's main menu by showing a user-friendly alert to the user.

	It takes care of storing the keyboard shortcut in `UserDefaults` for you.

	```
	import SwiftUI
	import KeyboardShortcuts

	struct PreferencesView: View {
		var body: some View {
			HStack {
				Text("Toggle Unicorn Mode:")
				KeyboardShortcuts.Recorder(for: .toggleUnicornMode)
			}
		}
	}
	```
	*/
	public struct Recorder: NSViewRepresentable { // swiftlint:disable:this type_name
		/// :nodoc:
		public typealias NSViewType = RecorderCocoa

		private let name: Name
		private let onChange: ((_ shortcut: Shortcut?) -> Void)?

		/**
		- Parameter name: Strongly-typed keyboard shortcut name.
		- Parameter onChange: Callback which will be called when the keyboard shortcut is changed/removed by the user. This can be useful when you need more control. For example, when migrating from a different keyboard shortcut solution and you need to store the keyboard shortcut somewhere yourself instead of relying on the built-in storage. However, it's strongly recommended to just rely on the built-in storage when possible.
		*/
		public init(
			for name: Name,
			onChange: ((_ shortcut: Shortcut?) -> Void)? = nil
		) {
			self.name = name
			self.onChange = onChange
		}

		/// :nodoc:
		public func makeNSView(context: Context) -> NSViewType { .init(for: name, onChange: onChange) }

		/// :nodoc:
		public func updateNSView(_ nsView: NSViewType, context: Context) {
			nsView.shortcutName = name
		}
	}
}

@available(macOS 10.15, *)
struct SwiftUI_Previews: PreviewProvider {
	static var previews: some View {
		KeyboardShortcuts.Recorder(for: .init("xcodePreview"))
	}
}
