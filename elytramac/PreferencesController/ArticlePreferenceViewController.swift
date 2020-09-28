import Cocoa

final class ArticlePreferenceViewController: NSViewController, PreferencePane {
    
	let preferencePaneIdentifier = Preferences.PaneIdentifier.article
	let preferencePaneTitle = "Reader"
    let toolbarItemIcon = NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: "Article Reader Settings")!

    override var nibBundle: Bundle? { Bundle(for: type(of: self)) }
    
	override var nibName: NSNib.Name? { "ArticlePreferenceViewController" }

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup stuff here
        
	}
    
}
