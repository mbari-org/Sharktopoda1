//
//  ServerCoordinator.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/22/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Cocoa

/*
 This object is created at application startup and lives the entire life of the app.
 It maintains the MessageHandler, vending it to objects that may need it.
 It watches the creation of various view controllers and coordinates them with the MessageHandler.
 
 It also is a responder that handles menu items and can validate them.
 It should be set as the Application's next responder to support this behavior
 */
class ServerCoordinator: NSResponder {

    lazy var messageHandler : MessageHandler = {
        $0.nextInterpreterConfigurator = self
        return $0
    } (MessageHandler())
    
    var videoCoordinator : SharkVideoCoordination?
    
    override init() {
        super.init()

        // listen for any server view controllers to be loaded
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageHandlerViewControllerDidLoad(_:)),
                                                         name: MessageHandlerViewController.Notifications.DidLoad, object: nil)
    
        if NSUserDefaults.standardUserDefaults().startServerOnStartup {
            startServer(self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // when a MessageHandlerViewController loads, set its MessageHandler through dependency injection
    func messageHandlerViewControllerDidLoad(notification:NSNotification) {
        guard let viewController = notification.object as? MessageHandlerViewController else { return }
        
        viewController.messageHandler = messageHandler
    }
    
    @IBAction func startServer(sender:AnyObject) {
        
        messageHandler.startServerOnPort(NSUserDefaults.standardUserDefaults().preferredServerPort)
    }
    
    @IBAction func stopServer(sender:AnyObject) {
        
        messageHandler.stopServer()
    }
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        
        if menuItem.action == #selector(startServer(_:)) {
                return !messageHandler.server.running
        }
        else if menuItem.action == #selector(stopServer(_:)) {
            return messageHandler.server.running
        }
        return super.validateMenuItem(menuItem)
    }
}

extension ServerCoordinator : SharkCommandInterpreterConfigurator {
    
    func configureInterpreter(interpreter inInterpreter: SharkCommandInterpreter) {

        inInterpreter.openCallback = { url, uuid, command, callback in
            
            var response : SharkResponse?
            
            do {
                try self.videoCoordinator?.openVideoAtURL(url, usingUUID: NSUUID(UUIDString: uuid)!)
                response = VerboseSharkResponse(successfullyCompletedCommand: command)
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
            }
            
            callback(response!)
        }

        inInterpreter.playCallback = { uuid, rate, command, callback in
            
            var response : SharkResponse?
            do {
                try self.videoCoordinator?.playVideoWithUUID(uuid: NSUUID(UUIDString: uuid)!, rate: rate)
                response = VerboseSharkResponse(successfullyCompletedCommand: command)
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
            }
            callback(response!)
        }
        
        inInterpreter.pauseCallback = { uuid, command, callback in
            
            var response : SharkResponse?
            do {
                try self.videoCoordinator?.pauseVideoWithUUID(uuid: NSUUID(UUIDString: uuid)!)
                response = VerboseSharkResponse(successfullyCompletedCommand: command)
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
            }
            callback(response!)
        }
        
        inInterpreter.showCallback = { uuid, command, callback in
            
            var response : SharkResponse?
            do {
                try self.videoCoordinator?.focusWindowForVideoWithUUID(uuid: NSUUID(UUIDString: uuid)!)
                response = VerboseSharkResponse(successfullyCompletedCommand: command)
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
            }
            callback(response!)
        }
        
        inInterpreter.getInfoForAllVideosCallback = { command, callback in
            
            var response : SharkResponse?
            do {
                guard let info = try self.videoCoordinator?.returnAllVideoInfo() else {
                    let error = NSError(domain: "ServerCoordinator", code: 11, userInfo:
                        [NSLocalizedDescriptionKey: "Unable to retrieve info for videos"])
                    response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
                    callback(response!)
                    return
                }
                response = VerboseSharkResponse(successfullyCompletedCommand: command, payload: ["videos":info])
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
            }
            callback(response!)
        }
        
        inInterpreter.getFrontmostVideoInfoCallback = { command, callback in
            
            var response : SharkResponse?
            do {
                guard let info = try self.videoCoordinator?.returnInfoForFrontmostVideo() else {
                    let error = NSError(domain: "ServerCoordinator", code: 13, userInfo:
                        [NSLocalizedDescriptionKey: "Unable to retrieve info for frontmost video"])
                    response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
                    callback(response!)
                    return
                }
                response = VerboseSharkResponse(successfullyCompletedCommand: command, payload: info)
           }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
            }
            callback(response!)
        }
        
        inInterpreter.getVideoStatusCallback = { uuid, command, callback in
            
            var response : SharkResponse?
            do {
                guard let status = try self.videoCoordinator?.requestPlaybackStatusForVideoWithUUID(uuid: NSUUID(UUIDString: uuid)!) else {
                    let error = NSError(domain: "ServerCoordinator", code: 14, userInfo:
                        [NSLocalizedDescriptionKey: "Unable to retrieve playback status for frontmost video"])
                    response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
                    callback(response!)
                    return
                }
                response = VerboseSharkResponse(successfullyCompletedCommand: command, payload: ["status":status.rawValue])
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
            }
            callback(response!)
       }
        
/*      The following is useful (we needed to be able to do this before we could do some other things), but not part of the spec
         
        inInterpreter.getInfoForVideoWithUUIDCallback = { uuid, command, callback in
            
            var response : SharkResponse?
            do {
                guard let info = try self.videoCoordinator?.returnInfoForVideoWithUUID(NSUUID(UUIDString: uuid)!) else {
                    let error = NSError(domain: "ServerCoordinator", code: 12, userInfo:
                        [NSLocalizedDescriptionKey: "Unable to retrieve info for video with uuid \(uuid)"])
                   response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
                    callback(response!)
                    return
                }
                response = VerboseSharkResponse(successfullyCompletedCommand: command, payload: info)
           }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error, canSendAnyway: true)
            }
            
            callback(response!)
        }
 */

    }
}
