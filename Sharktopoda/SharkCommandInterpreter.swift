//
//  SharkCommandInterpreter.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/21/16.
//

import Foundation
import CoreMedia

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
class SharkCommandInterpreter {
    
    struct Errors {
        static let CommandNotYetImplemented = 1
        static let MissingValue = 2
        static let InvalidUUID = 3

    }

    
    func handle(_ command:SharkCommand) {
        
        // NOTE: the interpreter can callback sending an error,
        // but only the client class can callback sending success
        // since it is the one that has to implement a successful completion
        
        switch command.verb {
        case .connect:
            connect(command)
            
        case .open:
            open(command)
        case .close:
            close(command)
        case .show:
            show(command)
            
        case .getVideoInfo:
            getVideoInfo(command)
        case .getAllVideosInfo:
            getInfoForAllVideos(command)
            
        case .getStatus:
            getVideoStatus(command)
            
        case .play:
            play(command)
        case .pause:
            pause(command)
            
        case .getElapsedTime:
            getElapsedTime(command)
        case .advanceToTime:
            advanceToTime(command)
        case .framecapture:
            captureCurrentFrame(command)
        case .frameAdvance:
            frameAdvance(command)
            
            // not needed, compiler complains,
            // but I'm leaving it here as a reminder in case new commands are ever added
//        default:
//            let error = NSError(domain: "SharkCommandInterpreter", code: Errors.CommandNotYetImplemented, userInfo: [NSLocalizedDescriptionKey: "\"\(command.verb)\" not yet implemented"])
//            callbackError(error, forCommand: command)
        }
    }
    
    
    var connectCallback : (_ port:UInt16, _ host:String?) -> () = { _, _ in }
    func connect(_ command:SharkCommand) {
        guard let port = command.port else {
            callbackErrorForMissingParameter("port", forCommand: command)
            return
        }
        
        connectCallback(port, command.host)
    }
    
    var openCallback : (_ url:URL, _ uuid:UUID, _ command:SharkCommand) -> () = { _, _, _ in }
    func open(_ command:SharkCommand) {
        guard let url = command.url else {
            callbackErrorForMissingParameter("url", forCommand: command)
            return
        }
        guard let uuid = uuidFromCommand(command) else { return }
        
        openCallback(url as URL, uuid.UUID! as UUID, command)
    }
    
    var closeCallback : (_ uuid:UUID, _ command:SharkCommand) -> () = { _, _ in }
    func close(_ command:SharkCommand) {
        guard let uuid = uuidFromCommand(command) else { return }
        
        closeCallback(uuid.UUID! as UUID, command)
    }

    var showCallback : (_ uuid:UUID, _ command:SharkCommand) -> () = { _, _ in }
    func show(_ command:SharkCommand) {
        guard let uuid = uuidFromCommand(command) else { return }

        showCallback(uuid.UUID! as UUID, command)
    }

    var getInfoForVideoWithUUIDCallback : (_ uuid:UUID, _ command:SharkCommand) -> () = { _, _ in }
    var getFrontmostVideoInfoCallback : (_ command:SharkCommand) -> () = { _ in }
    func getVideoInfo(_ command:SharkCommand) {
            getFrontmostVideoInfoCallback(command)
    }
    
    var getInfoForAllVideosCallback : (_ command:SharkCommand) -> () = { _ in }
    func getInfoForAllVideos(_ command:SharkCommand) {
        getInfoForAllVideosCallback(command)
    }
    
    var playCallback : (_ uuid:UUID, _ rate:Double, _ command:SharkCommand) -> () = { _, _, _ in }
    func play(_ command:SharkCommand) {
        guard let uuid = uuidFromCommand(command) else { return }

        let rate = command.rate
        playCallback(uuid.UUID! as UUID, rate, command)
    }
    
    var pauseCallback : (_ uuid:UUID, _ command:SharkCommand) -> () = { _, _ in }
    func pause(_ command:SharkCommand) {
        guard let uuid = uuidFromCommand(command) else { return }

        pauseCallback(uuid.UUID! as UUID, command)
    }

    var getVideoStatusCallback : (_ uuid:UUID, _ command:SharkCommand) -> () = { _, _ in }
    func getVideoStatus(_ command:SharkCommand) {
        guard let uuid = uuidFromCommand(command) else { return }

        getVideoStatusCallback(uuid.UUID! as UUID, command)
    }

    
    var getElapsedTimeCallback : (_ uuid:UUID, _ command:SharkCommand) -> () = { _, _ in }
    func getElapsedTime(_ command:SharkCommand) {
        guard let uuid = uuidFromCommand(command) else { return }

        getElapsedTimeCallback(uuid.UUID! as UUID, command)
    }
    
    var advanceToTimeCallback : (_ uuid:UUID, _ time:UInt, _ command:SharkCommand) -> () = { _, _, _ in }
    func advanceToTime(_ command:SharkCommand) {
        guard let uuid = uuidFromCommand(command) else { return }
        guard let time = command.elapsedTime else {
            callbackErrorForMissingParameter("elapsed_time_millis", forCommand: command)
            return
        }
        
        advanceToTimeCallback(uuid.UUID! as UUID, time, command)
    }
    
    var captureCurrentFrameCallback : (_ uuid:UUID, _ imageLocation:URL, _ imageReferenceUUID:UUID, _ command:SharkCommand) -> () = { _, _, _, _ in }
    func captureCurrentFrame(_ command:SharkCommand) {
        guard let uuid = uuidFromCommand(command) else { return }
        guard let imageLocation = command.imageLocation else {
            callbackErrorForMissingParameter("image_location", forCommand: command)
            return
        }
        guard let imageReferenceUUID = command.imageReferenceUUID else {
            callbackErrorForMissingParameter("image_reference_uuid", forCommand: command)
            return
        }
        captureCurrentFrameCallback(uuid.UUID! as UUID, imageLocation as URL, imageReferenceUUID.UUID! as UUID, command)
    }
    
    
    var frameAdvanceCallback : (_ uuid:UUID, _ command:SharkCommand) -> () = { _, _ in }
    func frameAdvance(_ command:SharkCommand) {
        guard let uuid = uuidFromCommand(command) else { return }
        
        frameAdvanceCallback(uuid.UUID! as UUID, command)
    }

    // MARK:- Convenience

    fileprivate func uuidFromCommand(_ command:SharkCommand) -> SharkCommand.UUID? {
        guard let uuid = command.uuid else {
            callbackErrorForMissingParameter("uuid", forCommand: command)
            return nil
        }
        if !uuid.isValidUUID  {
            callbackErrorForMalformedUUID(uuid, forCommand: command)
            return nil
        }
        return uuid
    }

    // MARK:- Error Handling
    
    func missingParameterErrorForCommand(_ command:SharkCommand, parameter:String) -> NSError {
        return NSError(domain: "SharkCommandInterpreter", code: Errors.MissingValue, userInfo: [NSLocalizedDescriptionKey: "command \"\(command.verb)\" has no value \"\(parameter)\""])
    }
    
    func callbackError(_ error:NSError, forCommand command:SharkCommand) {
        let response = VerboseSharkResponse(failedCommand:command, error:error)
        command.processResponse?(response)
    }
    
    func callbackErrorForMissingParameter(_ parameter:String, forCommand command:SharkCommand) {
        let error = missingParameterErrorForCommand(command, parameter: parameter)
        callbackError(error, forCommand: command)
    }
    
    func callbackErrorForMalformedUUID(_ uuid:SharkCommand.UUID, forCommand command:SharkCommand) {
        let error = NSError(domain: "SharkCommandInterpreter", code: Errors.InvalidUUID, userInfo: [NSLocalizedDescriptionKey : "\(uuid) is not a valid UUID"])
        let response = VerboseSharkResponse(failedCommand:command, error:error)
        command.processResponse?(response)
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
