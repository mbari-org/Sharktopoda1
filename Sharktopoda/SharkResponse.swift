//
//  SharkCommandResponse.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/21/16.
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
    
    var dictionaryRepresentation : [String:JSONObject] {

        var out = [String:JSONObject]()
        out["response"] = command.verb.rawValue as JSONObject
        out["status"] = success.rawValue as JSONObject

        for (key, value) in payload {
            var dictValue = value
            if let uuid = value as? UUID {
                dictValue = uuid.ITUString
            }
            out[key] = dictValue
        }

        // if the client asked for a verbose response,
        // then incude the other parameters and the error in the reponse
        if command.wantsVerboseResponse {
            out["data"] = command.data as JSONObject

            out["error"] = error?.userInfo as JSONObject
        }
        
        return out
    }
    
    var jsonSafeDictionaryRepresentation : [String:JSONObject] {
        
        let json = makeJSONSafe(dictionaryRepresentation)
        return json
    }
    
    var dataRepresentation : Data? {
        do {
            return try JSONSerialization.data(withJSONObject: jsonSafeDictionaryRepresentation, options: JSONSerialization.WritingOptions(rawValue:0))
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
        
        commandDictionary.removeValue(forKey: "response")
        commandDictionary.removeValue(forKey: "status")
        self.payload = commandDictionary
    }
}
