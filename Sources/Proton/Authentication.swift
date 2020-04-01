//
//  Authentication.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//
import Foundation
import UIKit
import LocalAuthentication

public class Authentication {
    
    static let shared = Authentication()
    
    private init() {}
    
    public func authenticationEnabled() -> Bool {
        
        let context = LAContext()
        var authError: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            
            return true
            
        }
        
        return false
        
    }
    
    public func authenticate(completion: @escaping (Bool, String?, Int?) -> Void) {
        
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        
        var authError: NSError?
        let reasonString = "Used to authenticate and secure your EOS wallet data"
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reasonString) { success, evaluateError in
                
                if success {
                    
                    // User authenticated successfully
                    DispatchQueue.main.async {
                        completion(true, nil, nil)
                    }
                    
                } else {
                    
                    // User did not authenticate successfully
                    guard let error = evaluateError else {
                        DispatchQueue.main.async {
                            completion(false, nil, nil)
                        }
                        return
                    }
                    
                    // If you have choosen the 'Fallback authentication mechanism selected' (LAError.userFallback). Handle gracefully
                    
                    let message = self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code)
                    print(message)
                    
                    DispatchQueue.main.async {
                        completion(false, message, error._code)
                    }
                
                }
                
            }
            
        } else {
            
            guard let error = authError else {
                DispatchQueue.main.async {
                    completion(false, nil, nil)
                }
                return
            }
            
            // Show appropriate alert if biometry/TouchID/FaceID is lockout or not enrolled
            
            let message = self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code)
            print(message)
            
            DispatchQueue.main.async {
                completion(false, message, error._code)
            }

        }
        
    }
    
    internal func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
        
        var message = ""
        
        switch errorCode {
            
        case LAError.authenticationFailed.rawValue:
            message = "The user failed to provide valid credentials"
            
        case LAError.appCancel.rawValue:
            message = "Authentication was cancelled by application"
            
        case LAError.invalidContext.rawValue:
            message = "The context is invalid"
            
        case LAError.notInteractive.rawValue:
            message = "Not interactive"
            
        case LAError.passcodeNotSet.rawValue:
            message = "Passcode is not set on the device"
            
        case LAError.systemCancel.rawValue:
            message = "Authentication was cancelled by the system"
            
        case LAError.userCancel.rawValue:
            message = "The user did cancel"
            
        case LAError.userFallback.rawValue:
            message = "The user chose to use the fallback"
            
        default:
            message = evaluatePolicyFailErrorMessageForLA(errorCode: errorCode)
        }
        
        return message
    }
    
    internal func evaluatePolicyFailErrorMessageForLA(errorCode: Int) -> String {
        
        var message = ""

        switch errorCode {
        case LAError.biometryNotAvailable.rawValue:
            message = "Authentication could not start because the device does not support biometric authentication."
            
        case LAError.biometryLockout.rawValue:
            message = "Authentication could not continue because the user has been locked out of biometric authentication, due to failing authentication too many times."
            
        case LAError.biometryNotEnrolled.rawValue:
            message = "Authentication could not start because the user has not enrolled in biometric authentication."
            
        default:
            message = "Did not find error code on LAError object"
        }
        
        return message
        
    }
    
//    func getAuthRequiredPopup() -> PopupDialog {
//
//        let popup = PopupDialog.getDialog(withTitle: "Passcode Required", description: "Lynx Wallet requires that you have at least a phone passcode set so that you can save and retrieve your sensitive data securely. We highly suggest also enabling FaceID or TouchID.", buttons: nil)
//
//        return popup
//
//    }

}

