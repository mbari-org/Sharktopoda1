//
//  NSJSONDictionaryHelpers.swift
//  SharktopodaTest
//
//  Created by Joseph Wardell on 8/24/16.
//

import Foundation

// given a dictionary that COULD be safe to convert to JSON,
// return one that is GUARANTEED to be JSON-safe,
// though that might be missing some individuals entries that were not JSON-safe
//
// NOTE: when I say guaranteed, this has been tested against JSON-style dictionaries in THIS APP ONLY without any issues, ymmv

func makeJSONSafe(dictionary:[String:AnyObject?]) -> [String:AnyObject] {
    
    var out = [String:AnyObject]()
    
    for (key, value) in dictionary {
        if let number = value as? NSNumber {
            out[key] = number
        }
        else if let string = value as? NSString {
            out[key] = string
        }
        else if let array = value as? NSArray {
            if NSJSONSerialization.isValidJSONObject(array) {
                out[key] = array
            }
            else {
                out[key] = NSNull()
            }
        }
        else if let dict = value as? NSDictionary {
            if  NSJSONSerialization.isValidJSONObject(dict) {
                out[key] = dict
            }
            else {
                out[key] = makeJSONSafe(dict as! [String:NSObject])
            }
        }
        else if let null = value as? NSNull {
            out[key] = null
        }
        else if let stringconvertible = value as? CustomStringConvertible {
            out[key] = stringconvertible.description
        }
        else {
            // not a JSON-Safe type and can't convert it to one, so just leave a placeholder
            out[key] = NSNull()
        }
    }
    
    // check one last time to see if there's something else that doesn't work...
    if !NSJSONSerialization.isValidJSONObject(out) {
        return [:]
    }
    
    return out
}
