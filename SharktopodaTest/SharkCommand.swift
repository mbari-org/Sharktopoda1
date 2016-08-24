//
//  SharkCommand.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/21/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation

typealias JSONObject = AnyObject

/*
 Encapsulates the data sent as a command from the client.
 Mainly, we use this to make sure that only valid commands are accepted
 */
struct SharkCommand {
    
    let verb : CommandVerb
    let data : [String:JSONObject]
    let address : String
    
    
    // MARK:- CommandVerb

    enum CommandVerb : String {
        case connect
        case open
        case show
        case getVideoInfo = "request video information"
        case getAllVideosInfo = "request all information"
        case play
        case pause
        case getElapsedTime = "request elapsed time"
        case requestStatus = "request status"
        case advanceToTime = "seek elapsed time"
        case framecapture
        case frameAdvance = "frame advance"
        
        var requiredParameters : [String] {
            switch self {
            case .connect:
                return ["port"]
            case .open:
                return ["url","uuid"]
            case .show:
                return ["uuid"]
                
            // TODO: fill out the rest of these
                // or at least the ones I currently support
                
            default:
                return []
            }
        }
    }
    
    // MARK:- Variables

    // a shorthand to make reading data from the command a little simpler
    subscript(key:String) -> JSONObject? {
        return data[key]
    }
    
    // convenience variables that read from the data dictionary (really, the original JSON dictionary)
    var url : NSURL? {
        guard let url = data["url"] as? String else { return nil }
        return NSURL(string: url)
    }
    
    var uuid : String? {    // TODO: switch to NSUUID, it makes for cleaner calling
        return data["uuid"] as? String
    }

    var host : String? {
        return data["host"] as? String ?? address
    }

    var port : UInt16? {
        if let out = data["port"] as? UInt16 {
            return out
        }
        guard let port = data["port"] as? String else { return nil }
        return UInt16(port)
    }

    var rate : Double {
        
        if let out = data["rate"] as? Double {
            return out
        }
        let rateString = data["rate"] as? String ?? "1"
        return Double(rateString)!
    }
    
    var timeStamp : UInt32? {
 
        if let out = data["elapsed_time_millis"] as? UInt32 {
            return out
        }
        guard let port = data["elapsed_time_millis"] as? String else { return nil }
        return UInt32(port)
    }
    
    var imageLocation : NSURL? {
        guard let url = data["image_location"] as? String else { return nil }
        return NSURL(string: url)
    }

    var imageReferenceUUID : String? {    // TODO: switch to NSUUID
        return data["image_reference_uuid"] as? String
    }
    
    var wantsVerboseResponse : Bool {
        return data["verbose_response"] as? Bool ?? false
    }

}

// MARK:- init from JSON

extension SharkCommand {
    
    init?(json:JSONObject, sentFrom address:String) {
        guard var commandDictionary = json as? [String:JSONObject] else { return nil }      // make sure it's a JSON dictionary
        guard let commandVerb = commandDictionary["command"] as? String else { return nil } // that has a command entry
        guard let command = CommandVerb(rawValue: commandVerb) else { return nil }          // that is a known command entry
        
        // make sure we have all necessary parameters
        // TODO: bring this back for more security
        //        for thisParameter in command.requiredParameters {
        //            if nil == commandDictionary[thisParameter] {
        //                return nil
        //            }
        //        }
        
        // TODO: for more security, make sure that every key in the command is a known required or optional parameter
        
        self.verb = command
        commandDictionary.removeValueForKey("command")
        self.data = commandDictionary
        
        self.address = address
    }
}

extension SharkCommand : CustomStringConvertible {
    
    var description : String {
        return "Command:\(verb)\n\(data)"
    }
}

