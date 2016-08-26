//
//  UDPService.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/21/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation


/*
 This is a simple UDP service that accepts messages on one port at a time, 
 and sends them to a callback.
 */
final class UDPService: NSObject {
    
    private(set) var running = false
    private(set) var port : PortNumber?

    // TODO:6 try a background queue
    private var q : dispatch_queue_t = dispatch_get_main_queue()
    
    private lazy var udpSocket : GCDAsyncUdpSocket = {
        return GCDAsyncUdpSocket(delegate: self, delegateQueue: self.q)
    }()
    
    // callbacks
    var didStartListening : (service:UDPService) -> () = {_ in }
    var didStopListening : (service:UDPService) -> () = {_ in }
    var didReceiveJSON : (json:AnyObject, from:String, service:UDPService) -> () = {_ in }
    var didReceiveMessage : (message:String, from:String, service:UDPService) -> () = {_ in }   // less preferred, but we can accept any UTF8 message
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

// MARK:- GCDAsyncUdpSocketDelegate

extension UDPService : GCDAsyncUdpSocketDelegate {
    
    func udpSocketDidClose(sock: GCDAsyncUdpSocket, withError error: NSError?) {
        port = nil
        running = false
        didStopListening(service:self)
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket, didReceiveData data: NSData, fromAddress inAddress: NSData, withFilterContext filterContext: AnyObject?) {
        
        guard let address = GCDAsyncUdpSocket.hostFromAddress(inAddress) else { return }
        
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue:0))
            didReceiveJSON(json: json, from: address, service:self)
        }
        catch {
            
            // it's not valid json, but maybe it's a valid string
            if let message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                didReceiveMessage(message: message, from: address, service:self)
            }
        }
    }
}