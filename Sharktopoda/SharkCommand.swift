//
//  SharkCommand.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/21/16.
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
    let address : UDPClient
    
    let processResponse : ((SharkResponse)->())?
    
    // MARK:- CommandVerb
    
    enum CommandVerb : String {
        case connect
        case open
        case close
        case show
        case getVideoInfo = "request video information"
        case getAllVideosInfo = "request all information"
        case play
        case pause
        case getElapsedTime = "request elapsed time"
        case getStatus = "request status"
        case advanceToTime = "seek elapsed time"
        case framecapture
        case frameAdvance = "frame advance"
        
        var requiredParameters : [String] {
            switch self {
            case .connect:
                return ["port"]
            case .open:
                return ["url","uuid"]
            case .close:
                return ["uuid"]
            case .show, .play, .pause, .getElapsedTime, .getStatus, .frameAdvance:
                return ["uuid"]
            case .getVideoInfo, .getAllVideosInfo:
                return []
            case .advanceToTime:
                return ["uuid", "elapsed_time_millis"]
            case .framecapture:
                return ["uuid", "image_location", "image_reference_uuid"]
            }
        }

        var sendsResponseToClient : Bool {
            switch self {
            case .open, .getVideoInfo, .getAllVideosInfo, .getElapsedTime, .getStatus, .play, .pause:
                return true
            default:
                return false
            }
        }
        
        var sendsResponseToRemoteServer : Bool {
            switch self {
            case .framecapture:
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
    var url : URL? {
        guard let url = data["url"] as? String else { return nil }
        return URL(string: url)
    }
    
    // an object that is meant to be a UUID
    // it may be one, or it may be some other string
    struct UUID : CustomStringConvertible {
        var object : AnyObject
        var UUID : Foundation.UUID? {
            guard let s = object as? String else { return nil }
            return Foundation.UUID(uuidString: s)
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

    var host : String {
        return data["host"] as? String ?? "localhost"
    }

    var port : UInt16? {
        if let d = data["port"] as? Double {
            return UInt16(d)
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
    }
    
    var imageLocation : URL? {
        guard let url = data["image_location"] as? String else { return nil }
        return URL(string: url)
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
    
    init?(json:JSONObject, sentFrom address:UDPClient, processResponse callback:((SharkResponse)->())?=nil) {
        guard var commandDictionary = json as? [String:JSONObject] else { return nil }      // make sure it's a JSON dictionary
        guard let commandVerb = commandDictionary["command"] as? String else { return nil } // that has a command entry
        guard let command = CommandVerb(rawValue: commandVerb) else { return nil }          // that is a known command entry

        // NOTE: If this app were exposed to outside networks, 
        // it would make sense to include the following code 
        // to prevent ANY action if we received a malformed command.
        // as it is, leaving this out allows calling code 
        // to respond to this situation and report to the client if it wants,
        // which is more user-friendly
        //
        // make sure we have all necessary parameters
        //        for thisParameter in command.requiredParameters {
        //            if nil == commandDictionary[thisParameter] {
        //                return nil
        //            }
        //        }
        
        // NOTE: for even more security, you could make sure that every key in the command is a known required or optional parameter
        
        self.verb = command
        commandDictionary.removeValue(forKey: "command")
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

