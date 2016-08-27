//
//  SharkCommand.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/21/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation
import CoreMedia

typealias JSONObject = AnyObject


/*
 Encapsulates the data sent as a command from the client.
 Mainly, we use this to make sure that only valid commands are accepted
 */
struct SharkCommand {
    
    let verb : CommandVerb
    let data : [String:JSONObject]
    let address : String
    
    let processResponse : ((SharkResponse)->())?
    
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
        case getStatus = "request status"
        case advanceToTime = "seek elapsed time"
        case frameCapture
        case frameAdvance = "frame advance"
        
        var requiredParameters : [String] {
            switch self {
            case .connect:
                return ["port"]
            case .open:
                return ["url","uuid"]
            case .show, .play, .pause, .getElapsedTime, .getStatus, .frameAdvance:
                return ["uuid"]
            case .getVideoInfo, .getAllVideosInfo:
                return []
            case .advanceToTime:
                return ["uuid", "elapsed_time_millis"]
            case .frameCapture:
                return ["uuid", "image_location", "image_reference_uuid"]
            }
        }

        // TODO: verify that these are the only commands that return responses
        var sendResponseToCaller : Bool {
            switch self {
            case .open, .getVideoInfo, .getAllVideosInfo, .getElapsedTime, .getStatus:
                return true
            default:
                return false
            }
        }
        
        // TODO: rename this
        var sendResponseToSeparateClient : Bool {
            switch self {
            case .frameCapture:
                return true
            default:
                return false
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
    
    // an object that is meant to be a UUID
    // it may be one, or it may be some other string
    struct UUID : CustomStringConvertible {
        var object : AnyObject
        var UUID : NSUUID? {
            guard let s = object as? String else { return nil }
            return NSUUID(UUIDString: s)
        }
        var isValidUUID : Bool {
            return nil != UUID
        }
        var description: String {
            if let string = object as? CustomStringConvertible { return string.description }
            return "SharkCommand.UUID"
        }
    }
    
    var uuid : UUID? {
        guard let uuid = data["uuid"] else { return nil }
        return UUID(object: uuid)
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
        
        switch data["rate"] {
        case (let d) where d is Double:
            return d as! Double
        case (let s) where s is String:
            return Double(s as! String) ?? 1
        default:return 1
        }
    }
    
    var elapsedTime : UInt? {
 
        switch data["elapsed_time_millis"] {
        case (let u) where u is UInt:
            return u as? UInt
        case (let s) where s is String:
            return UInt(s as! String)
        default:
            return nil
        }
        
//        if let out = data["elapsed_time_millis"] as? UInt {
//            return CMTime.timeWithMilliseconds(out)
//        }
//        guard let port = data["elapsed_time_millis"] as? String else { return nil }
//        guard let portInt = UInt(port) else { return nil }
//        return CMTime.timeWithMilliseconds(portInt)
    }
    
    var imageLocation : NSURL? {
        guard let url = data["image_location"] as? String else { return nil }
        return NSURL(string: url)
    }

    var imageReferenceUUID : UUID? {
        guard let uuid = data["image_reference_uuid"] else { return nil }
        return UUID(object: uuid)
    }
    
    var wantsVerboseResponse : Bool {
        return data["verbose_response"] as? Bool ?? false
    }

}

// MARK:- init from JSON

extension SharkCommand {
    
    init?(json:JSONObject, sentFrom address:String, processResponse callback:((SharkResponse)->())?=nil) {
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
        
        self.processResponse = callback
    }
}

extension SharkCommand : CustomStringConvertible {
    
    var description : String {
        return "Command:\(verb)\n\(data)"
    }
}

