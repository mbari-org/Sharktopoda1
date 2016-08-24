//
//  SharkCommandInterpreter.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/21/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation

/*
 Interprets commands that are sent from the client app,
 verifies that they're well-formed,
 then redirects them to callbacks
 
 It acts as a big dispatch table, tying commands to implementations.
 
 NOTE: if the interpreter doesn't have a callback set for a given command,
        then it will simply be dropped.  
        The caller may know about it, but no response will be sent.
        This is another layer of security, ensuring that only commands we are expecting are responded to.
 */
class SharkCommandInterpreter { // TODO: can this be a struct?
    
    func handle(command:SharkCommand, fromClient clientAddress:String, then callback:(SharkResponse) -> ()) {
        
        // NOTE: the interpreter can callback sending an error,
        // but only the client class can callback sending success
        // since it is the one that has to implement a successful completion
        
        switch command.verb {
        case .connect:
            connect(command, then:callback)
            
        case .open:
            open(command, then:callback)
        case .show:
            show(command, then:callback)
            
        case .getVideoInfo:
            getVideoInfo(command, then:callback)
        case .getAllVideosInfo:
            getInfoForAllVideos(command, then:callback)
            
        case .requestStatus:
            getVideoStatus(command, then:callback)
            
        case .play:
            play(command, then:callback)
        case .pause:
            pause(command, then:callback)
            
            // TODO: the following cases
//        case getElapsedTime = "request elapsed time"
//        case advanceToTime = "seek elapsed time"
//        case framecapture
//        case frameAdvance = "frame advance"
            
        default:
            let error = NSError(domain: "SharkCommandInterpreter", code: 10, userInfo: [NSLocalizedDescriptionKey: "\"\(command.verb)\" not yet implemented"])
            callbackError(error, forCommand: command, callback: callback)
        }
    }
    
    
    var connectCallback : (port:UInt16, host:String?, command:SharkCommand, then:(SharkResponse) -> ()) -> () = { _, _, _, _ in }
    func connect(command:SharkCommand, then callback:(SharkResponse) -> ()) {
        guard let port = command.port else {
            callbackErrorForMissingParameter("port", forCommand: command, callback: callback)
            return
        }
        
        connectCallback(port: port, host: command.host, command:command, then:callback)
    }
    
    var openCallback : (url:NSURL, uuid:String, command:SharkCommand, then:(SharkResponse) -> ()) -> () = { _, _, _, _ in }
    func open(command:SharkCommand, then callback:(SharkResponse) -> ()) {
        guard let url = command.url else {
            callbackErrorForMissingParameter("url", forCommand: command, callback: callback)
            return
        }
        guard let uuid = command.uuid else {
            callbackErrorForMissingParameter("uuid", forCommand: command, callback: callback)
            return
        }
        
        openCallback(url: url, uuid: uuid, command:command, then:callback)
    }
    
    var showCallback : (uuid:String, command:SharkCommand, then:(SharkResponse) -> ()) -> () = { _, _, _ in }
    func show(command:SharkCommand, then callback:(SharkResponse) -> ()) {
        guard let uuid = command.uuid else {
            callbackErrorForMissingParameter("uuid", forCommand: command, callback: callback)
            return
        }
        
        showCallback(uuid: uuid, command:command, then:callback)
    }

    var getInfoForVideoWithUUIDCallback : (uuid:String, command:SharkCommand, then:(SharkResponse) -> ()) -> () = { _, _, _ in }
    var getFrontmostVideoInfoCallback : (command:SharkCommand, then:(SharkResponse) -> ()) -> () = { _, _ in }
    func getVideoInfo(command:SharkCommand, then callback:(SharkResponse) -> ()) {
        if let uuid = command.uuid {
            getInfoForVideoWithUUIDCallback(uuid: uuid, command: command, then: callback)
        }
        else {
            getFrontmostVideoInfoCallback(command: command, then: callback)
        }
    }
    
    var getInfoForAllVideosCallback : (command:SharkCommand, then:(SharkResponse) -> ()) -> () = { _, _ in }
    func getInfoForAllVideos(command:SharkCommand, then callback:(SharkResponse) -> ()) {
        getInfoForAllVideosCallback(command: command, then: callback)
    }
    
    var playCallback : (uuid:String, rate:Double, command:SharkCommand, then:(SharkResponse) -> ()) -> () = { _, _, _, _ in }
    func play(command:SharkCommand, then callback:(SharkResponse) -> ()) {
        guard let uuid = command.uuid else {
            callbackErrorForMissingParameter("uuid", forCommand: command, callback: callback)
            return
        }
        let rate = command.rate
        playCallback(uuid: uuid, rate:rate, command:command, then:callback)
    }
    
    var pauseCallback : (uuid:String, command:SharkCommand, then:(SharkResponse) -> ()) -> () = { _, _, _ in }
    func pause(command:SharkCommand, then callback:(SharkResponse) -> ()) {
        guard let uuid = command.uuid else {
            callbackErrorForMissingParameter("uuid", forCommand: command, callback: callback)
            return
        }
        
        pauseCallback(uuid: uuid, command:command, then:callback)
    }

    var getVideoStatusCallback : (uuid:String, command:SharkCommand, then:(SharkResponse) -> ()) -> () = { _, _, _ in }
    func getVideoStatus(command:SharkCommand, then callback:(SharkResponse) -> ()) {
        
        guard let uuid = command.uuid else {
            callbackErrorForMissingParameter("uuid", forCommand: command, callback: callback)
            return
        }
        
        getVideoStatusCallback(uuid: uuid, command:command, then:callback)
    }

    // MARK:- Error Handling
    
    func missingParameterErrorForCommand(command:SharkCommand, parameter:String) -> NSError {
        return NSError(domain: "SharkCommandInterpreter", code: 11, userInfo: [NSLocalizedDescriptionKey: "command \"\(command.verb)\" has no value \"\(parameter)\""])
    }
    
    func callbackError(error:NSError, forCommand command:SharkCommand, callback:(SharkResponse) -> ()) {
        let response = VerboseSharkResponse(failedCommand:command, error:error)
        callback(response)
    }
    
    func callbackErrorForMissingParameter(parameter:String, forCommand command:SharkCommand, callback:(SharkResponse) -> ()) {
        let error = missingParameterErrorForCommand(command, parameter: parameter)
        callbackError(error, forCommand: command, callback: callback)
    }
}

/*
 An object that can (help to) configure a SharkCommandInterpreter.
 
 */
protocol SharkCommandInterpreterConfigurator {
    
    // given a command interpreter, modify it as you see fit to make it handle ceertain commands the way you want
    // It's even possible that one configurator can pass a command interpreter on to another one,
    // with each one applying some change or another to the way the interpreter handles different commands
    func configureInterpreter(interpreter inInterpreter:SharkCommandInterpreter)

}