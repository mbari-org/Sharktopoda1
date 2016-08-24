//
//  NSUserDefaults+ServerPreferences.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/21/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation


extension NSUserDefaults {
    
    var preferredServerPort : UInt16 {
        get {
            return UInt16(integerForKey("server_port"))
        }
        set {
            setInteger(Int(newValue), forKey: "server_port")
        }
    }
    
    var startServerOnStartup : Bool {
        get {
            return boolForKey("load_on_startup")
        }
        set {
            setBool(newValue, forKey: "load_on_startup")
        }
    }
}