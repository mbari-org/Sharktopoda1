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
class SharkCommandInterpreter { // TODO:5 can this be a struct? I think so with just a little tweaking
    
    func handle(command:SharkCommand, fromClient clientAddress:String) {
        
        // NOTE: the interpreter can callback sending an error,
        // but only the client class can callback sending success
        // since it is the one that has to implement a successful completion
        
        switch command.verb {
        case .connect:
            connect(command)
            
        case .open:
            open(command)
        case .show:
            show(command)
            
        case .getVideoInfo:
            getVideoInfo(command)
        case .getAllVideosInfo:
            getInfoForAllVideos(command)
            
        case .requestStatus:
            getVideoStatus(command)
            
        case .play:
            play(command)
        case .pause:
            pause(command)
            
            // TODO:6 the following cases
//        case getElapsedTime = "request elapsed time"
//        case advanceToTime = "seek elapsed time"
//        case framecapture
//        case frameAdvance = "frame advance"
            
        default:
            let error = NSError(domain: "SharkCommandInterpreter", code: 10, userInfo: [NSLocalizedDescriptionKey: "\"\(command.verb)\" not yet implemented"])
            callbackError(error, forCommand: command)
        }
    }
    
    
    var connectCallback : (port:UInt16, host:String?) -> () = { _, _ in }
    func connect(command:SharkCommand) {
        guard let port = command.port else {
            callbackErrorForMissingParameter("port", forCommand: command)
            return
        }
        
        connectCallback(port: port, host: command.host)
    }
    
    var openCallback : (url:NSURL, uuid:String, command:SharkCommand) -> () = { _, _, _ in }
    func open(command:SharkCommand) {
        guard let url = command.url else {
            callbackErrorForMissingParameter("url", forCommand: command)
            return
        }
        guard let uuid = command.uuid else {
            callbackErrorForMissingParameter("uuid", forCommand: command)
            return
        }
        
        openCallback(url: url, uuid: uuid, command:command)
    }
    
    var showCallback : (uuid:String, command:SharkCommand) -> () = { _, _ in }
    func show(command:SharkCommand) {
        guard let uuid = command.uuid else {
            callbackErrorForMissingParameter("uuid", forCommand: command)
            return
        }
        
        showCallback(uuid: uuid, command:command)
    }

    var getInfoForVideoWithUUIDCallback : (uuid:String, command:SharkCommand) -> () = { _, _ in }
    var getFrontmostVideoInfoCallback : (command:SharkCommand) -> () = { _ in }
    func getVideoInfo(command:SharkCommand) {
        if let uuid = command.uuid {
            getInfoForVideoWithUUIDCallback(uuid: uuid, command: command)
        }
        else {
            getFrontmostVideoInfoCallback(command: command)
        }
    }
    
    var getInfoForAllVideosCallback : (command:SharkCommand) -> () = { _ in }
    func getInfoForAllVideos(command:SharkCommand) {
        getInfoForAllVideosCallback(command: command)
    }
    
    var playCallback : (uuid:String, rate:Double, command:SharkCommand) -> () = { _, _, _ in }
    func play(command:SharkCommand) {
        guard let uuid = command.uuid else {
            callbackErrorForMissingParameter("uuid", forCommand: command)
            return
        }
        let rate = command.rate
        playCallback(uuid: uuid, rate:rate, command:command)
    }
    
    var pauseCallback : (uuid:String, command:SharkCommand) -> () = { _, _ in }
    func pause(command:SharkCommand) {
        guard let uuid = command.uuid else {
            callbackErrorForMissingParameter("uuid", forCommand: command)
            return
        }
        
        pauseCallback(uuid: uuid, command:command)
    }

    var getVideoStatusCallback : (uuid:String, command:SharkCommand) -> () = { _, _ in }
    func getVideoStatus(command:SharkCommand) {
        
        guard let uuid = command.uuid else {
            callbackErrorForMissingParameter("uuid", forCommand: command)
            return
        }
        
        getVideoStatusCallback(uuid: uuid, command:command)
    }

    // MARK:- Error Handling
    
    func missingParameterErrorForCommand(command:SharkCommand, parameter:String) -> NSError {
        return NSError(domain: "SharkCommandInterpreter", code: 11, userInfo: [NSLocalizedDescriptionKey: "command \"\(command.verb)\" has no value \"\(parameter)\""])
    }
    
    func callbackError(error:NSError, forCommand command:SharkCommand) {
        let response = VerboseSharkResponse(failedCommand:command, error:error)
        command.processResponse?(response)
    }
    
    func callbackErrorForMissingParameter(parameter:String, forCommand command:SharkCommand) {
        let error = missingParameterErrorForCommand(command, parameter: parameter)
        callbackError(error, forCommand: command)
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