import Cocoa

final class ImagesPreferenceViewController: NSViewController, PreferencePane {
    
	let preferencePaneIdentifier = Preferences.PaneIdentifier.images
	let preferencePaneTitle = "Images"
    let toolbarItemIcon = NSImage(systemSymbolName: "photo.on.rectangle", accessibilityDescription: "Image Settings")!

    override var nibBundle: Bundle? { Bundle(for: type(of: self)) }
    
	override var nibName: NSNib.Name? { "ImagesPreferenceViewController" }

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup stuff here
        
	}
    
}

extension ImagesPreferenceViewController {
    
}
