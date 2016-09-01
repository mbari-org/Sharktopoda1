//
//  UDPService.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/21/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation

// a wrapper protocol for interacting with client code
// description will return a string representation of the address
protocol UDPClient : CustomStringConvertible {}

/*
 This is a simple UDP service that accepts messages on one port at a time,
 and sends them to a callback.
 
 It also is able to respond to a message given the address from which the message was sent.
 */
final class UDPService: NSObject {
    
    struct Errors {
        static let UnknownError = 1
    }

    
    private(set) var running = false
    private(set) var port : PortNumber?
    
    private var q : dispatch_queue_t = dispatch_queue_create("UDPService", DISPATCH_QUEUE_SERIAL)
    
    private lazy var udpSocket : GCDAsyncUdpSocket = {
        return GCDAsyncUdpSocket(delegate: self, delegateQueue: self.q)
    }()
    
    // callbacks
    var didStartListening : (service:UDPService) -> () = {_ in }
    var didStopListening : (service:UDPService) -> () = {_ in }
    var didReceiveJSON : (json:AnyObject, from:UDPClient, service:UDPService) -> () = {_ in }
    var didReceiveMessage : (message:String, from:UDPClient, service:UDPService) -> () = {_ in }   // less preferred, but we can accept any UTF8 message
    var didSendResponse : () -> () = {}
    var failedToSendResponse : (error:NSError) -> () = { _ in }
    
    var responseTag = 0
}

// MARK:- Listening

extension UDPService {
    
    func startListening(onPort inPort:PortNumber) throws {
        
        // only allow this server to accept input on one port at a time
        if running {
            stopListening()
        }
        
        try udpSocket.bindToPort(inPort)
        try udpSocket.beginReceiving()
        
        port = inPort
        running = true
        
        didStartListening(service:self)
    }
    
    func stopListening() {
        udpSocket.close()
    }
}

// MARK:- Reponding

extension UDPService {
    
    func sendResponse(data:NSData, toClient client:UDPClient) {
        
        guard let client = client as? UDPClientAddress else { return }
        
        udpSocket.sendData(data, toAddress: client.address, withTimeout: 20, tag: responseTag)
        responseTag += 1
    }
}

// MARK:- GCDAsyncUdpSocketDelegate

extension UDPService : GCDAsyncUdpSocketDelegate {
    
    func udpSocketDidClose(sock: GCDAsyncUdpSocket, withError error: NSError?) {
        port = nil
        running = false
        dispatch_async(dispatch_get_main_queue()) {
            
            self.didStopListening(service:self)
        }

    }
    
    private struct UDPClientAddress : UDPClient, CustomStringConvertible {
        let address : NSData
        var description : String {
            return GCDAsyncUdpSocket.hostFromAddress(address)!
        }
        
        init?(addressData:NSData) {
            guard let _ = GCDAsyncUdpSocket.hostFromAddress(addressData) else { return nil }
            self.address = addressData
        }
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket, didReceiveData data: NSData,
                   fromAddress inAddress: NSData,
                               withFilterContext filterContext: AnyObject?) {
        
        guard let address = UDPClientAddress(addressData: inAddress) else { return }
        
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue:0))
            dispatch_async(dispatch_get_main_queue()) {
                
                self.didReceiveJSON(json: json, from: address, service:self)
            }

        }
        catch {
            
            // it's not valid json, but maybe it's a valid string
            if let message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                dispatch_async(dispatch_get_main_queue()) {
                    
                    self.didReceiveMessage(message: message, from: address, service:self)
                }
            }
        }
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            
            self.didSendResponse()
        }
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: NSError?) {
        let error = error ?? NSError(domain: "UDPService", code: Errors.UnknownError, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
        dispatch_async(dispatch_get_main_queue()) {
            
            self.failedToSendResponse(error: error)
        }
    }
}