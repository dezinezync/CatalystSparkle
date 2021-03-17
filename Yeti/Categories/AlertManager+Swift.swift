//
//  AlertManager+Swift.swift
//  Elytra
//
//  Created by Nikhil Nigade on 17/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation

extension AlertManager {
    
    static public func showAlert(title: String, message: String?, confirm: String?, cancel: String?) {
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        let window = scene.windows.first
        
        guard var vc = window?.rootViewController else {
            return
        }
        
        if vc.presentedViewController != nil {
            vc = vc.presentedViewController ?? vc
        }
        
        showAlert(title: title, message: message, confirm: confirm, cancel: cancel, from: vc)
        
    }
    
    static public func showAlert(title: String, message: String?, confirm: String?, cancel: String?, from: UIViewController) {
        
        showAlert(title: title, message: message, confirm: confirm, confirmHandler: nil, cancel: cancel, cancelHandler: nil, from: from)
        
    }
    
    static public func showAlert(title: String, message: String?, confirm: String?, confirmHandler: ((UIAlertAction) -> Void)?, cancel: String?, cancelHandler: ((UIAlertAction) -> Void)?, from: UIViewController) {
        
        let avc = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        
        if let confirmTitle = confirm {
            
            let confirm = UIAlertAction.init(title: confirmTitle, style: .default, handler: confirmHandler)
            
            avc.addAction(confirm)
            
        }
        
        let cancel = UIAlertAction.init(title: cancel ?? "Okay", style: .cancel, handler: cancelHandler)
        
        avc.addAction(cancel)
        
        from.present(avc, animated: true, completion: nil)
        
    }
    
    static public func showDestructiveAlert(title: String, message: String?, confirm: String?, confirmHandler: ((UIAlertAction) -> Void)?, cancel: String?, cancelHandler: ((UIAlertAction) -> Void)?, from: UIViewController) {
        
        let avc = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        
        if let confirmTitle = confirm {
            
            let confirm = UIAlertAction.init(title: confirmTitle, style: .destructive, handler: confirmHandler)
            
            avc.addAction(confirm)
            
        }
        
        let cancel = UIAlertAction.init(title: cancel ?? "Okay", style: .cancel, handler: cancelHandler)
        
        avc.addAction(cancel)
        
        from.present(avc, animated: true, completion: nil)
        
    }

    
}
