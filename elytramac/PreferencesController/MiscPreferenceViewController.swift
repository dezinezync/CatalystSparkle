import Cocoa

final class MiscPreferenceViewController: NSViewController, PreferencePane {
    
	let preferencePaneIdentifier = Preferences.PaneIdentifier.misc
	let preferencePaneTitle = "Misc"
    let toolbarItemIcon = NSImage(systemSymbolName: "dial.max", accessibilityDescription: "Miscellaneous Settings")!
        
    @IBOutlet weak var twitterAppsMenu: NSMenu!
    @IBOutlet weak var twitterAppsPopup: NSPopUpButton!
    
    override var nibBundle: Bundle? { Bundle(for: type(of: self)) }
    
	override var nibName: NSNib.Name? { "MiscPreferenceViewController" }
    
    @objc dynamic var twitterApp : String = "" {
        
        didSet {
            
            print("Changed twitter app pref to \(twitterApp) from \(oldValue)")
            
            UserDefaults.standard.setValue(twitterApp.lowercased(), forKey: "externalapp.twitter")
            UserDefaults.standard.synchronize()
            
        }
        
    }

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup stuff here
        setupTwitterApps()
        
	}
    
    func setupTwitterApps () {
        
        twitterApp = UserDefaults.standard.string(forKey: "externalapp.twitter") ?? ""
        
        let canOpenTwitter = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "maccatalyst.com.atebits.Tweetie2")
        let canOpenTweetbot = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.tapbots.Tweetbot3Mac")
        let canOpenTwitterific = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.iconfactory.Twitterrific5")
        
        var addedAtleastOne = false
        
        if (canOpenTwitter != nil) {
            
            let menuItem = NSMenuItem(title: "Twitter", action: nil, keyEquivalent: "")
            menuItem.representedObject = "twitter"
            twitterAppsMenu.addItem(menuItem)
            
            if (twitterApp == menuItem.representedObject as! String) {
                twitterAppsPopup.select(menuItem)
            }
            
            if (addedAtleastOne == false) { addedAtleastOne = true }
            
        }
        
        if (canOpenTweetbot != nil) {
            
            let menuItem = NSMenuItem(title: "Tweetbot", action: nil, keyEquivalent: "")
            menuItem.representedObject = "tweetbot"
            twitterAppsMenu.addItem(menuItem)
            
            if (twitterApp == menuItem.representedObject as! String) {
                twitterAppsPopup.select(menuItem)
            }
            
            if (addedAtleastOne == false) { addedAtleastOne = true }
            
        }
        
        if (canOpenTwitterific != nil) {
            
            let menuItem = NSMenuItem(title: "Twitterific", action: nil, keyEquivalent: "")
            menuItem.representedObject = "twitterific"
            twitterAppsMenu.addItem(menuItem)
            
            if (twitterApp == menuItem.representedObject as! String) {
                twitterAppsPopup.select(menuItem)
            }
            
            if (addedAtleastOne == false) { addedAtleastOne = true }
            
        }
        
        if (addedAtleastOne == false || twitterApp == "") {
            
            let menuItem = NSMenuItem(title: "None", action: nil, keyEquivalent: "")
            menuItem.isEnabled = false
            twitterAppsMenu.addItem(menuItem)
            
            twitterAppsPopup.select(menuItem)
            
        }
        
    }
    
}
