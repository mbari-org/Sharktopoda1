//
//  MessageHandler.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/22/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation

class MessageHandler: NSObject {
    
    struct Notifications {
        static let DidStartListening = "MessageHandlerDidStartListening"
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
            self.log("invalid message from \(address): \(message)", label:.error)
        }
        $0.didReceiveJSON = { json, address, _ in
            self.log("Received JSON from \(address): \(json)")
            self.handleJSON(json, sentFrom:address)
        }
        return $0
    }(UDPService())
    

    lazy var sender : UDPSender = {
        $0.didSend = { message, address, port, timeSent in
            self.log("message sent to \(address):\(port) at \(timeSent): \(message)")
        }
        $0.failedToSend = { message, address, port, timeSent, error in
            self.log("failed to send message to \(address):\(port) at \(timeSent): \(message)\n\nerror:\(error)", label:.error)
        }
        return $0
    }(UDPSender())

    lazy var interpreter : SharkCommandInterpreter = {
        
        // this class gets the first shot at configuring the interpreter
        self.configureInterpreter(interpreter: $0)
        return $0
    }(SharkCommandInterpreter())

    let log = Log()
    
    var nextInterpreterConfigurator : SharkCommandInterpreterConfigurator?
    
    
    // MARK:- Toggling Server
    
    func startServerOnPort(port:PortNumber) {
        
        let portToTry = port
        do {
            try server.startListening(onPort: portToTry)
        }
        catch {
            // TODO: some common POSIX errors (e.g. 13:Permission Denied, should be handled more elegantly)
            self.log("Error starting server on port \(portToTry): \(error)", label: .error)
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
    
    private func handleJSON(json:JSONObject, sentFrom address:String) {
        
        guard let command = SharkCommand(json: json, sentFrom:address) else {
            self.log("not a command: \(json)", label:.error)
            return
        }
        
        self.log("got a command: \(command)", label:.important)
        
        interpreter.handle(command, fromClient: address, then:processResponse)
    }
    
    private func hostForResponse(response:VerboseSharkResponse) -> String? {
        // If we were using the connect message as a handshake, then we'd want to:
        // - check a lookup table for host names associated with the address
        return response.command.host
    }

    private func portForResponse(response:VerboseSharkResponse) -> UInt16? {
        // If we were using the connect message as a handshake, then we'd want to:
        // - check a lookup table for port numbers associated with the host
        
        // instead, we just return the default return port
        return NetworkingDefaults.Ports.returnPort
    }

    private func processResponse(response:SharkResponse) {
        
        // has to be a verbose response, or else we can't send it
        let response = response as! VerboseSharkResponse
        
        if response.succeeded || response.allowSendingOnFailure {
            sendResponse(response)
        }
        else if let error = response.error {
            log(error)
        }
        else {
            log("Unknown error in response: \(response)")
        }
    }
    
    private func sendResponse(response:VerboseSharkResponse) {
        
        guard let data = response.dataRepresentation else {
            log("Malformed response: \(response)", label:.error)
            return
        }
        guard let host = hostForResponse(response) else {
            log("No known host to send response \(response)", label:.error)
            return
        }
        guard let port = portForResponse(response) else {
            log("No known port for response \(response)", label:.error)
            return
        }
        
        sender.sendData(data, to: host, onPort: port)
    }

    // If we were using the connect message as a handshake, then we'd want to:
    // - all commands except connect must follow a previous connect: call
    // - connections time out after a reasonable time
}

// MARK:- SharkCommandInterpreterConfigurator

extension MessageHandler : SharkCommandInterpreterConfigurator {
    
    func configureInterpreter(interpreter inInterpreter:SharkCommandInterpreter) {
        
        // these two implementations are summy implementations,
        // a subclass will override them and develop something much more interesting
        
        inInterpreter.connectCallback = { port, host, command, callback in
            
            // NOTE: per the spec, this is only used for
            // "additional out-of-band messages to (outside of the UDP command -> response messages)"
            // I would think it would be a way to do a handshake before receiving any other messages,
            // but that's not my understanding of the spec right now...
            // if this were the case, then we'd want to:
            // - verify that this host is allowed (perhaps as simple as a blacklist)
            // - build a data structure of allowed host and port for this address
            
            // but for now, all we do is log the fact that a connection was made,
            // as if the connection has been
            self.log("Connected to \(host):\(port)", label:.start)
            
            // in fact, we don't even callback here
            // callback(nil)
        }
        
        inInterpreter.openCallback = { url, uuid, command, callback in
            
            let response : SharkResponse
            
            // for now, respond with a success for local urls and a failure for all others
            if url.scheme == "file" {
                response = VerboseSharkResponse(successfullyCompletedCommand: command)
            }
            else {
                response = VerboseSharkResponse(failedCommand: command, error: NSError(domain: "MessageHandler", code: 888, userInfo: [NSLocalizedDescriptionKey:"We don't support non-file URLs"]), canSendAnyway:true)
            }
            callback(response)
        }
        
        // if we have a next configurator in the chain, then give it a chance at configuring the interpreter
        nextInterpreterConfigurator?.configureInterpreter(interpreter: inInterpreter)
    }
}

// MARK:- Logging


extension MessageHandler : Logging {
    
    func log(message:String, label:LogLabel) {
        
        NSLog(message)  // TODO: Do I need this?
        log.log(message, label: label)
    }
}