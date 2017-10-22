//
//  NSUserDefaults+ServerPreferences.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/21/16.
//

import Foundation


extension UserDefaults {
    
    var preferredServerPort : UInt16 {
        get {
            return UInt16(integer(forKey: "server_port"))
        }
        set {
            set(Int(newValue), forKey: "server_port")
        }
    }
    
    var startServerOnStartup : Bool {
        get {
            return bool(forKey: "load_on_startup")
        }
        set {
            set(newValue, forKey: "load_on_startup")
        }
    }
}
