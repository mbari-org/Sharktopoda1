//
//  MessageHandler.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/22/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation

final class MessageHandler: NSObject {
    
    struct Notifications {
        static let DidStartListening = "MessageHandlerDidStartListening"
        static let DidFailToStartListening = "MessageHandlerDidFailToStartListening"
        static let DidStopListening = "MessageHandlerDidStopListening"
    }
    
    lazy var server : UDPService = {
        $0.didStartListening = { server in
            self.log("Server Started on port \(server.port!)", label:.start)
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidStartListening, object: self)
        }
        $0.didStopListening = { _ in
            self.log("Server Stopped", label:.end)
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidStopListening, object: self)
        }
        $0.didReceiveMessage = { message, address, _ in
            // we don't do anything with non-json messages
            self.log("invalid message from \(address): \(message)", label:.error)
        }
        $0.didReceiveJSON = { json, address, _ in
            self.log("Received JSON from \(address): \(json)")
            self.handleJSON(json, sentFrom:address)
        }
        $0.didSendResponse = {
            self.log("Response Sent")
        }
        $0.failedToSendResponse = { error in
            self.log(error)
        }
        return $0
    }(UDPService())
    
    
    private lazy var remoteSender : UDPSender = {
        $0.didSend = { message, address, port, timeSent in
            self.log("message sent to \(address):\(port) at \(timeSent): \(message)")
        }
        $0.failedToSend = { message, address, port, timeSent, error in
            self.log("failed to send message to \(address):\(port) at \(timeSent): \(message)\n\nerror:\(error)", label:.error)
        }
        return $0
    }(UDPSender())

    private var remoteServer : String?
    private var remoteServerPort : UInt16?
    
    lazy var interpreter : SharkCommandInterpreter = {
        
        // this class gets the first shot at configuring the interpreter
        self.configureInterpreter(interpreter: $0)
        return $0
    }(SharkCommandInterpreter())
    
    lazy var log : Log = {
        
        do {
            // write the log file to /Library/Logs/Sharktopoda and have one log file for each time Sharktopoda starts up
            let library = try NSFileManager.defaultManager().URLForDirectory(.LibraryDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
            let logs = library.URLByAppendingPathComponent("Logs")
            let sharktopoda = logs.URLByAppendingPathComponent("Sharktopoda")
            
            let now = NSDate()
            let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
            let components = calendar.components([.Year, .Month, .Day, .Hour, .Minute, .Second], fromDate: now)
            let logname = "\(components.year)_\(components.month)_\(components.day) \(components.hour)_\(components.minute)_\(components.second).txt"
            let log = sharktopoda.URLByAppendingPathComponent(logname)
            $0.savePath = log
        }
        catch let error as NSError {
            print("error creating url for logging: \(error)")
        }
        return $0
    }(Log())
//    let log = Log()
    
    var nextInterpreterConfigurator : SharkCommandInterpreterConfigurator?
    
    
    // MARK:- Toggling Server
    
    func startServerOnPort(port:PortNumber) {
        
        let portToTry = port
        do {
            try server.startListening(onPort: portToTry)
        }
        catch let error as NSError {
            self.log("Error starting server on port \(portToTry): \(error)", label: .error)
            
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidFailToStartListening, object: self, userInfo: ["error":error, "port":NSNumber(unsignedShort: portToTry)])
        }
    }
    
    func stopServer() {
        server.stopListening()
    }
    
    func toggleServerOnPort(port:PortNumber) {
        
        if server.running {
            stopServer()
        }
        else {
            startServerOnPort(port)
        }
    }
    
    
    // MARK:- Handling Commands from the client
    
    private func handleJSON(json:JSONObject, sentFrom address:UDPClient) {
        
        guard let command = SharkCommand(json: json, sentFrom:address, processResponse:processResponse) else {
            self.log("not a command: \(json)", label:.error)
            return
        }
        
        self.log("got a command: \(command)", label:.important)
        
        interpreter.handle(command)
    }
    
    
    private func processResponse(response:SharkResponse) {
        
        // has to be a verbose response, or else we can't send it
        let response = response as! VerboseSharkResponse
        
        if response.commandVerb.sendsResponseToClient {
            sendResponse(response)
        }
        else if response.commandVerb.sendsResponseToRemoteServer {
            sendResponseToRemoteServer(response)
        }
        else {
            log.log("Did not send generated response \(response)", label: response.succeeded ? .important : .error)
        }
    }
    
    private func sendResponse(response:VerboseSharkResponse) {
        
        guard let data = response.dataRepresentation else {
            log("Malformed response: \(response)", label:.error)
            return
        }

        log("Sending Response \(response)")
        
        server.sendResponse(data, toClient:response.command.address)
    }

    private func sendResponseToRemoteServer(response:VerboseSharkResponse) {
        
        guard let data = response.dataRepresentation else {
            log("Malformed response: \(response)", label:.error)
            return
        }
        guard let server = remoteServer,
            serverPort = remoteServerPort else {
                log("Not enough information to send response to remote server \(remoteServer) on port \(remoteServerPort)\nresponse:\(response)", label:.error)
                return
        }
        
        log("Sending Reponse to remove server \(response)")
        
        remoteSender.sendData(data, to: server, onPort: serverPort)
    }
}

// MARK:- SharkCommandInterpreterConfigurator

extension MessageHandler : SharkCommandInterpreterConfigurator {
    
    func configureInterpreter(interpreter inInterpreter:SharkCommandInterpreter) {
        
        // MessageHandler only worries about the 'connect' command
        // it leaves another layer to handle the other, more video-oriented commands
        inInterpreter.connectCallback = { port, host in
            
            self.remoteServer = host
            self.remoteServerPort = port
            
            self.log("Connected to \(self.remoteServer):\(self.remoteServerPort)", label:.start)
        }
        
        // if we have a next configurator in the chain, then give it a chance at configuring the interpreter
        nextInterpreterConfigurator?.configureInterpreter(interpreter: inInterpreter)
    }
}

// MARK:- Logging



extension MessageHandler : Logging {
    
    func log(message:String, label:LogLabel) {
        
        #if false
            // to simultaneously log everything to the console as well, include this line
            NSLog(message)
        #endif
        log.log(message, label: label)
    }
}