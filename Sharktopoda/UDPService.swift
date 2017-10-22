//
//  UDPService.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/21/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

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

    
    fileprivate(set) var running = false
    fileprivate(set) var port : PortNumber?
    
    fileprivate var q : DispatchQueue = DispatchQueue(label: "UDPService", attributes: [])
    
    fileprivate lazy var udpSocket : GCDAsyncUdpSocket = {
        return GCDAsyncUdpSocket(delegate: self, delegateQueue: self.q)
    }()
    
    // callbacks
    var didStartListening : (_ service:UDPService) -> () = {_ in }
    var didStopListening : (_ service:UDPService) -> () = {_ in }
    var didReceiveJSON : (_ json:AnyObject, _ from:UDPClient, _ service:UDPService) -> () = {_ in }
    var didReceiveMessage : (_ message:String, _ from:UDPClient, _ service:UDPService) -> () = {_ in }   // less preferred, but we can accept any UTF8 message
    var didSendResponse : () -> () = {}
    var failedToSendResponse : (_ error:NSError) -> () = { _ in }
    
    var responseTag = 0
}

// MARK:- Listening

extension UDPService {
    
    func startListening(onPort inPort:PortNumber) throws {
        
        // only allow this server to accept input on one port at a time
        if running {
            stopListening()
        }
        
        try udpSocket.bind(toPort: inPort)
        try udpSocket.beginReceiving()
        
        port = inPort
        running = true
        
        didStartListening(self)
    }
    
    func stopListening() {
        udpSocket.close()
    }
}

// MARK:- Reponding

extension UDPService {
    
    func sendResponse(_ data:Data, toClient client:UDPClient) {
        
        guard let client = client as? UDPClientAddress else { return }
        
        udpSocket.send(data, toAddress: client.address, withTimeout: 20, tag: responseTag)
        responseTag += 1
    }
}

// MARK:- GCDAsyncUdpSocketDelegate

extension UDPService : GCDAsyncUdpSocketDelegate {
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: NSError?) {
        port = nil
        running = false
        DispatchQueue.main.async {
            
            self.didStopListening(self)
        }

    }
    
    fileprivate struct UDPClientAddress : UDPClient, CustomStringConvertible {
        let address : Data
        var description : String {
            return GCDAsyncUdpSocket.host(fromAddress: address)!
        }
        
        init?(addressData:Data) {
            guard let _ = GCDAsyncUdpSocket.host(fromAddress: addressData) else { return nil }
            self.address = addressData
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data,
                   fromAddress inAddress: Data,
                               withFilterContext filterContext: AnyObject?) {
        
        guard let address = UDPClientAddress(addressData: inAddress) else { return }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue:0))
            DispatchQueue.main.async {
                
                self.didReceiveJSON(json as AnyObject, address, self)
            }

        }
        catch {
            
            // it's not valid json, but maybe it's a valid string
            if let message = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String {
                DispatchQueue.main.async {
                    
                    self.didReceiveMessage(message, address, self)
                }
            }
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        DispatchQueue.main.async {
            
            self.didSendResponse()
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: NSError?) {
        let error = error ?? NSError(domain: "UDPService", code: Errors.UnknownError, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
        DispatchQueue.main.async {
            
            self.failedToSendResponse(error)
        }
    }
}
