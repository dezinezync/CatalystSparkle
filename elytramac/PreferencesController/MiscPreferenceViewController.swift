import Cocoa

final class MiscPreferenceViewController: NSViewController, PreferencePane {
    
	let preferencePaneIdentifier = Preferences.PaneIdentifier.misc
	let preferencePaneTitle = "Misc"
    let toolbarItemIcon = NSImage(systemSymbolName: "dial.max", accessibilityDescription: "Miscellaneous Settings")!

    override var nibBundle: Bundle? { Bundle(for: type(of: self)) }
    
	override var nibName: NSNib.Name? { "MiscPreferenceViewController" }

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup stuff here
        
	}
    
}
