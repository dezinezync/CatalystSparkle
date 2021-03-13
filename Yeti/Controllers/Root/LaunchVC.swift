//
//  LaunchVC.swift
//  Elytra
//
//  Created by Nikhil Nigade on 12/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import AuthenticationServices
import Networking
import DBManager
import Models

@objc class LaunchVC: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var getStartedButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    
    weak var signinButton: ASAuthorizationAppleIDButton?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        getStartedButton.isHidden = true
        
        let style: ASAuthorizationAppleIDButton.Style = traitCollection.userInterfaceStyle == .dark ? .white : .black
        
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .continue, authorizationButtonStyle: style)
        
        button.addTarget(self, action: #selector(didTapSignin(_:)), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.heightAnchor.constraint(equalToConstant: 44),
            button.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 40),
            button.widthAnchor.constraint(equalToConstant: (320 - 24))
        ])
        
        signinButton = button
        
        view.backgroundColor = .systemBackground
        navigationController?.isNavigationBarHidden = true
        
        if let attrs = titleLabel.attributedText?.mutableCopy() as? NSMutableAttributedString {
         
            let bigFont = UIFont.systemFont(ofSize: 40, weight: .heavy)
            let baseMetrics = UIFontMetrics(forTextStyle: .title1)
            
            let baseFont = baseMetrics.scaledFont(for: bigFont)
            titleLabel.font = baseFont
            
            let elytra = (attrs.string as NSString).range(of: "Elytra")
            var purple: UIColor? = .systemIndigo
            
            if purple == nil {
                purple = .purple
            }
            
            attrs.setAttributes([
                .font: baseFont,
                .foregroundColor: UIColor.label
            ], range: NSMakeRange(0, attrs.length))
            
            attrs.setAttributes([
                .font: baseFont,
                .foregroundColor: purple!
            ], range: elytra)
            
            titleLabel.attributedText = attrs
            
        }
        
        subtitleLabel.textColor = .secondaryLabel
        
    }
    
    @objc func didTapSignin(_ sender: Any?) {
        
        guard let s = sender as? ASAuthorizationAppleIDButton,
              s == signinButton else {
            return
        }
        
        #if DEBUG
        process(uuid: "000768.e759fc828ab249ad98ceefc5f80279b3.1145")
        return
        #endif
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = []
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        
        controller.performRequests()
        
    }
    
    func process(uuid: String) {
     
        print("Got \(uuid)")
        
        let user = User()
        user.uuid = uuid
        
//        FeedsManager.shared.user = user
        
        FeedsManager.shared.getUser(userID: uuid) { [weak self] (result) in
            
            guard let sself = self else {
                return
            }
            
            switch result {
            case .failure(let error as NSError):
                
                if error.localizedDescription.contains("User not found") {
                    
                    // create the user
                    FeedsManager.shared.createUser(uuid: uuid) { (result) in
                        
                        switch result {
                        case .failure(let error as NSError):
                            AlertManager.showGenericAlert(withTitle: "Creating Account Failed", message: error.localizedDescription)
                            
                        case .success(let u):
                            sself.setupUser(u, existing: false)
                        }
                        
                    }
                    
                }
                
                AlertManager.showGenericAlert(withTitle: "Error Logging In", message: error.localizedDescription)
                
            case .success(let u):
                
                sself.setupUser(u, existing: true)
                
            }
            
        }
        
    }
    
    func setupUser(_ u: User?, existing: Bool = false) {
        
        guard let user = u else {
            AlertManager.showGenericAlert(withTitle: "Error Logging In", message: "No user information received for your account")
            return
        }
        
        DBManager.shared.user = user
        
        // @TODO: Trial VC
        navigationController?.dismiss(animated: true, completion: nil)
        
    }
    
}

extension LaunchVC: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
        signinButton?.isEnabled = true
        
        let err = error as NSError
        
        if err.code == 1001 {
            // cancel was tapped
        }
        else {
            print("Authorization failed with error: \(err.localizedDescription)")
            AlertManager.showGenericAlert(withTitle: "Log In Failed", message: error.localizedDescription)
        }
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        signinButton?.isEnabled = true
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
        
            AlertManager.showGenericAlert(withTitle: "Error Logging In", message: "No Login information was received from Sign In with Apple.")
            
            return
            
        }
        
        print("Authorized with credentials: %@", authorization)
        
        process(uuid: credential.user)
        
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    
}

