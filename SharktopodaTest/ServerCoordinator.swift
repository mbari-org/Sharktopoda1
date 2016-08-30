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
final class ServerCoordinator: NSResponder {

    lazy var messageHandler : MessageHandler = {
        $0.nextInterpreterConfigurator = self
        return $0
    } (MessageHandler())
    
    var videoCoordinator : SharkVideoCoordination
    
    init(videoCoordinator:SharkVideoCoordination) {
        
        self.videoCoordinator = videoCoordinator
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

        inInterpreter.openCallback = { url, uuid, command in
            
            self.videoCoordinator.openVideoAtURL(url, usingUUID:uuid) { success, error in
                
                if success {
                    command.processResponse?(VerboseSharkResponse(successfullyCompletedCommand: command))
                }
                else {
                    command.processResponse?(VerboseSharkResponse(failedCommand: command, error: error!))
                }
            }
        }

        inInterpreter.closeCallback = { uuid, command in
            
            var response : SharkResponse?
            do {
                try self.videoCoordinator.closeWindowForVideoWithUUID(uuid:uuid)
                response = VerboseSharkResponse(successfullyCompletedCommand: command)
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error)
            }
            command.processResponse?(response!)
        }

        inInterpreter.playCallback = { uuid, rate, command in
            
            var response : SharkResponse?
            do {
                try self.videoCoordinator.playVideoWithUUID(uuid:uuid, rate: rate)
                response = VerboseSharkResponse(successfullyCompletedCommand: command, payload:["uuid":uuid])
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error)
            }
            command.processResponse?(response!)
        }
        
        inInterpreter.pauseCallback = { uuid, command in
            
            var response : SharkResponse?
            do {
                try self.videoCoordinator.pauseVideoWithUUID(uuid:uuid)
                response = VerboseSharkResponse(successfullyCompletedCommand: command, payload:["uuid":uuid])
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error)
            }
            command.processResponse?(response!)
        }
        
        inInterpreter.showCallback = { uuid, command in
            
            var response : SharkResponse?
            do {
                try self.videoCoordinator.focusWindowForVideoWithUUID(uuid:uuid)
                response = VerboseSharkResponse(successfullyCompletedCommand: command)
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error)
            }
            command.processResponse?(response!)
        }
        
        inInterpreter.getInfoForAllVideosCallback = { command in
            
            var response : SharkResponse?
            do {
                let info = try self.videoCoordinator.returnAllVideoInfo()
                response = VerboseSharkResponse(successfullyCompletedCommand: command, payload: ["videos":info])
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error)
            }
            command.processResponse?(response!)
        }
        
        inInterpreter.getFrontmostVideoInfoCallback = { command in
            
            var response : SharkResponse?
            do {
                let info = try self.videoCoordinator.returnInfoForFrontmostVideo()
                response = VerboseSharkResponse(successfullyCompletedCommand: command, payload: info)
           }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error)
            }
            command.processResponse?(response!)
        }
        
        inInterpreter.getVideoStatusCallback = { uuid, command in
            
            var response : SharkResponse?
            do {
                let status = try self.videoCoordinator.requestPlaybackStatusForVideoWithUUID(uuid:uuid)
                response = VerboseSharkResponse(successfullyCompletedCommand: command, payload: ["uuid":uuid, "status":status.rawValue])
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error)
            }
            command.processResponse?(response!)
        }
        
        inInterpreter.getElapsedTimeCallback = { uuid, command in
            
            var response : SharkResponse?
            do {
                let elapsedTime = try self.videoCoordinator.requestElapsedTimeForVideoWithUUID(uuid: uuid)
                response = VerboseSharkResponse(successfullyCompletedCommand: command, payload: ["uuid":uuid, "elapsed_time_millis":elapsedTime])
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error)
            }
            command.processResponse?(response!)
        }
        
        inInterpreter.advanceToTimeCallback = { uuid, time, command in
            
            var response : SharkResponse?
            do {
                try self.videoCoordinator.advanceToTimeInMilliseconds(time, forVideoWithUUID: uuid)
                // TODO:10 perhaps we should get the ACTUAL time after the comand is called and return that?
                // see notes in PLayerVideoController...
                response = VerboseSharkResponse(successfullyCompletedCommand: command, payload: ["uuid":uuid, "elapsed_time_millis":time])
            }
            catch let error as NSError {
                response = VerboseSharkResponse(failedCommand: command, error: error)
            }
            command.processResponse?(response!)

        }
        
        inInterpreter.captureCurrentFrameCallback = { uuid, imageLocation, referenceUUID, command in
         
            do {
                try self.videoCoordinator.captureCurrentFrameForVideWithUUID(uuid:uuid, andSaveTo:imageLocation, referenceUUID:referenceUUID) { success, error, requestedTime, actualTime in

                    var response : SharkResponse?
                    if success {
                        let payload = ["elapsed_time_millis":actualTime!,
                                       "requested_time_millis":requestedTime!,
                                       "image_reference_uuid":referenceUUID,
                                       "image_location":imageLocation]
                        response = (VerboseSharkResponse(successfullyCompletedCommand: command, payload:payload))
                    }
                    else {
                        response = (VerboseSharkResponse(failedCommand: command, error: error!))
                    }
                    
                    command.processResponse?(response!)
                }
            }
            catch let error as NSError {
                let response = VerboseSharkResponse(failedCommand: command, error: error)
                command.processResponse?(response)
                
            }

        }
    }
}
