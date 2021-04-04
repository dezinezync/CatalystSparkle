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

    @discardableResult static public func showActivity(title: String?) -> UIAlertController? {
        
        #if targetEnvironment(macCatalyst)
        return nil
        #endif
        
        guard let delegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else {
            
            return nil
            
        }
        
        let coordinator: Coordinator = delegate.coordinator
        
        if coordinator.activityDialog != nil {
            
            coordinator.activityDialog?.dismiss(animated: false, completion: {
                
                AlertManager.showActivity(title: title)
                
            })
            
            return nil
            
        }
        
        let avc = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        avc.dz_configureContentView { contentView in
            
            guard let cv = contentView else {
                return
            }
            
            let activity = UIActivityIndicatorView(style: .large)
            activity.sizeToFit()
            activity.translatesAutoresizingMaskIntoConstraints = false
            activity.hidesWhenStopped = true
            
            cv.addSubview(activity)
            
            NSLayoutConstraint.activate([
                activity.widthAnchor.constraint(equalToConstant: activity.bounds.size.width),
                activity.heightAnchor.constraint(equalToConstant: activity.bounds.size.height),
                activity.centerXAnchor.constraint(equalTo: cv.centerXAnchor),
                activity.topAnchor.constraint(equalTo: cv.topAnchor, constant: 12)
            ])
            
            activity.startAnimating()
            
        }
        
        var from: UIViewController = coordinator.splitVC
        
        while (from.presentedViewController != nil) {
            from = from.presentedViewController!
        }
        
        from.present(avc, animated: true, completion: nil)
        
        return avc
        
    }
    
}
