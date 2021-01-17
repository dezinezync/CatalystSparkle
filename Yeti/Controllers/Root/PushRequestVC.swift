//
//  PushRequestVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 05/01/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit

@objc class PushRequestVC: UIViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var backgroundView: UIImageView!
    @IBOutlet weak var enableButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        contentView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.layer.cornerCurve = .continuous
        shadowView.layer.cornerCurve = .continuous
        
        shadowView.clipsToBounds = false
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 20)
        shadowView.layer.shadowRadius = 40
//        shadowView.layer.shadowPath = UIBezierPath.init(roundedRect: shadowView.frame, cornerRadius: 32).cgPath
        shadowView.layer.shadowOpacity = 0.54
        
        enableButton.layer.cornerCurve = .continuous
        
        view.alpha = 0
        close()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.1) { [weak self] in
            
            self?.view.alpha = 1
            
        } completion: { (_) in
            
            UIView.animate(withDuration: 0.215) { [weak self] in
                
                self?.open()
                
            } completion: { (_) in
                
            }
            
        }

        
    }
    
    // Mark: Animations
    
    func open () {
        
        shadowView.transform = .init(translationX: 0, y: 0)
        contentView.transform = .init(translationX: 0, y: 0)
        shadowView.alpha = 1
        contentView.alpha = 1
        
    }
    
    func close () {
        
        shadowView.transform = .init(translationX: 0, y: shadowView.frame.size.height)
        contentView.transform = .init(translationX: 0, y: contentView.frame.size.height)
        shadowView.alpha = 0
        contentView.alpha = 0
        
    }
    
    func updateCoordinator () {
        
        if let coordinator: NSObject = self.value(forKey: "mainCoordinator") as? NSObject {
            
            let selector = NSSelectorFromString("didTapCloseForPushRequest")
            
            coordinator.perform(selector)
            
        }
        
    }
    
    // MARK: Actions
    @IBAction func didTapEnable(_ sender: UIButton) {
        
        if let coordinator: NSObject = self.value(forKey: "mainCoordinator") as? NSObject {
         
            let completionBlock: @convention(block) (_ completed: Bool, _ error: NSError?) -> Void = { (completed: Bool, error: NSError?) in
                
                if (error != nil) {
                    return AlertManager.showGenericAlert(withTitle: "An Error Occurred", message: error?.localizedDescription ?? "", fromVC: self)
                }
                
                if (completed) {
                    return self.didTapClose(nil)
                }
                else {
                    
                    UIView.animate(withDuration: 0.1) { [weak self] in
                        
                        self?.view.alpha = 0
                        
                    } completion: { (_) in
                        
                        self.dismiss(animated: false, completion: nil)
                        
                    }
                    
                }
                
            }
            
            let selector = NSSelectorFromString("registerForNotifications:")
            
            coordinator.perform(selector, with: completionBlock)
            
        }
        else {
            print("Coordinator not available")
        }
        
    }
    
    @IBAction func didTapClose(_ sender: UIButton?) {
        
        updateCoordinator()
        
        UIView.animate(withDuration: 0.2) { [weak self] in
            
            self?.close()
            
        } completion: { (_) in
            
            UIView.animate(withDuration: 0.1) { [weak self] in
                
                self?.view.alpha = 0
                
            } completion: { (_) in
                
                self.dismiss(animated: false, completion: nil)
                
            }
            
        }
        
    }
    
}
