import Cocoa

final class GeneralPreferenceViewController: NSViewController, PreferencePane {
    
	let preferencePaneIdentifier = Preferences.PaneIdentifier.general
	let preferencePaneTitle = "General"
	let toolbarItemIcon = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General Settings")!

    @IBOutlet weak var accountID: NSTextField!
    @IBOutlet weak var deactivateButton: NSButton!
    
    override var nibBundle: Bundle? { Bundle(for: type(of: self)) }
    
	override var nibName: NSNib.Name? { "GeneralPreferenceViewController" }

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup stuff here
        let glue = AppKitGlue.shared()
        
        let accountIDValue = glue.appUserDefaults?.object(forKey: "accountID") as? String ?? ""
        
        guard accountIDValue == accountIDValue else {
            return
        }
        
        if (accountIDValue == "") {
            accountID.stringValue = "Set up your account"
            deactivateButton.isEnabled = false
        }
        
	}
    
}

extension GeneralPreferenceViewController {
    
    @IBAction func didTapDeactivate(_ sender: NSButton) {
            
        let answer = dialogYesCancel(question: "Are you sure you want to deactivate your account?", text: "You can always contact support@elytra.app to reactivate your account. Just make sure to note down your Account ID.", buttonTitle: nil)
        
        if (answer) {
            
            let glue = AppKitGlue.shared()
            glue.deactivateAccount { (completed, error: Error?) in
                
                if (error != nil) {
                    
                    dialogNoReturn(question: "An Error Occurred", text: error?.localizedDescription ?? "An unknown error occurred", buttonTitle: "Ok");
                    
                    return
                }
                
                if (completed) {
                    self.view.window?.windowController?.close()
                }
                
            }
            
        }
        
    }
    
}

func dialogNoReturn (question: String, text: String, buttonTitle: String) {
    
    let alert: NSAlert = NSAlert()
    
    alert.messageText = question
    alert.informativeText = text
    alert.alertStyle = .warning
    alert.addButton(withTitle: buttonTitle ?? "Yes")
    
    alert.runModal()
    
}

func dialogYesCancel(question: String, text: String, buttonTitle: String?) -> Bool {
    
    let alert: NSAlert = NSAlert()
    
    alert.messageText = question
    alert.informativeText = text
    alert.alertStyle = .warning
    alert.addButton(withTitle: buttonTitle ?? "Yes")
    alert.addButton(withTitle: "Cancel")
    
    let res = alert.runModal()
    
    return res == NSApplication.ModalResponse.alertFirstButtonReturn
    
}


