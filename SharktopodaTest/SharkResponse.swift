//
//  SharkCommandResponse.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/21/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation

enum SharkResponseStatus : String {
    case ok
    case failed
}

protocol SharkResponse {
    var commandVerb : SharkCommand.CommandVerb { get }
    var success : SharkResponseStatus { get }
    
    // any other information that should be passed along
    var payload : [String:JSONObject] { get }
}

extension SharkResponse {
    var succeeded : Bool {
        return success == .ok
    }
}

struct VerboseSharkResponse : SharkResponse {
    
    // the command that is being responded to
    let command : SharkCommand

    var commandVerb : SharkCommand.CommandVerb {
        return command.verb
    }

    // whether the command succeeded
    var success : SharkResponseStatus = .ok
    
    // an error if the command failed
    // may or may not be there if succeeded == false, depending on how it was created
    var error : NSError? = nil
    // by default, a failure won't be sent to the client in a response,
    // set this to true to allow a failure to be sent
    var allowSendingOnFailure = false
    
    // any other information that should be passed along
    var payload : [String:JSONObject] = [:]
    
    init(successfullyCompletedCommand:SharkCommand) {
        self.command = successfullyCompletedCommand
    }
    
    init(successfullyCompletedCommand:SharkCommand, payload:[String:JSONObject]) {
        self.command = successfullyCompletedCommand
        self.payload = payload
    }
    
    init(failedCommand:SharkCommand, error:NSError) {
        self.command = failedCommand
        self.error = error
        self.success = .failed
    }

    init(failedCommand:SharkCommand, error:NSError, canSendAnyway:Bool) {
        self.command = failedCommand
        self.error = error
        self.success = .failed
        self.allowSendingOnFailure = canSendAnyway
    }
    
    
    var dictionaryRepresentation : [String:JSONObject] {

        var out = [String:JSONObject]()
        out["response"] = command.verb.rawValue
        out["status"] = success.rawValue

        for (key, value) in payload {
            print("\(key): \(value)")
            out[key] = value
        }

        // if the client asked for a verbose response,
        // then incude the other parameters and the error in the reponse
        if command.wantsVerboseResponse {
            out["data"] = command.data

            out["error"] = error?.userInfo
        }
        print("out: \(out)")
        
        return out
    }
    
    var jsonSafeDictionaryRepresentation : [String:JSONObject] {
        
        let json = makeJSONSafe(dictionaryRepresentation)
        print("json: \(json)")
        return json
    }
    
    var dataRepresentation : NSData? {
        do {
            return try NSJSONSerialization.dataWithJSONObject(jsonSafeDictionaryRepresentation, options: NSJSONWritingOptions(rawValue:0))
        }
        catch {
            return nil
        }
    }
}

struct SimpleSharkResponse : SharkResponse {
    
    var commandVerb : SharkCommand.CommandVerb
    var success : SharkResponseStatus
    var payload : [String:JSONObject] = [:]
}

extension SimpleSharkResponse {
    
    init?(json:JSONObject) {
        guard var commandDictionary = json as? [String:JSONObject] else { return nil }          // make sure it's a JSON dictionary
        guard let commandWord = commandDictionary["response"] as? String else { return nil }    // that has a command entry
        guard let commandVerb = SharkCommand.CommandVerb(rawValue: commandWord) else { return nil }     // that is a known command entry
        guard let statusWord = commandDictionary["status"] as? String else { return nil }       // and has a status
        guard let status = SharkResponseStatus(rawValue: statusWord) else { return nil }            // that is a valid ResponseStatus
        
        // make sure we have all necessary parameters
        self.commandVerb = commandVerb
        self.success = status
        
        commandDictionary.removeValueForKey("response")
        commandDictionary.removeValueForKey("status")
        self.payload = commandDictionary
    }
}
