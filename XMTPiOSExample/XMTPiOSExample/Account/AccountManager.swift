//
//  AccountManager.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation
import XMTP

class AccountManager: ObservableObject {
	var account: Account

	init() {
		do {
			account = try Account.create()
		} catch {
			fatalError("Account could not be created: \(error)")
		}
	}
    
    static func getKey() -> String? {
        guard let plistPath = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            return nil
        }
        
        guard let plistDict = NSDictionary(contentsOfFile: plistPath) as? [String: Any] else {
                return nil // Failed to parse the plist
        }
        
        if let getKey = plistDict["UseKey"] as? String {
            return getKey
        } else {
            return nil
        }
    }
    
    static func generate(privateKeyString: String) throws -> Data {
         // Convert the private key string to Data
        
         guard let privateKeyData = Data(hex: privateKeyString) else {
             throw NSError(domain: "InvalidPrivateKey", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid private key format."])
         }
         return privateKeyData
     }
}
