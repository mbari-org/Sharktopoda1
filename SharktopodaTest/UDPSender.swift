//
//  UDPSender.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/21/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation

/*
 This is an object that can send messages via UDP
 It maintains a dictionary of messages sent and the times they were sent 
 */
class UDPSender: NSObject {

    private var q : dispatch_queue_t = dispatch_get_main_queue()
    
    private lazy var udpSocket : GCDAsyncUdpSocket = {
        return GCDAsyncUdpSocket(delegate: self, delegateQueue: self.q)
    }()

    var sendTag : Int = 0
    var messages : [(date:NSDate,address:String,port:PortNumber,data:NSData)] = []
    
    func sendMessage(message:String, to address:String, onPort port:PortNumber) -> Bool {
        guard let data = message.dataUsingEncoding(NSUTF8StringEncoding) else { return false }

        sendData(data, to: address, onPort: port)
        
        return true
    }
    
    func sendData(data:NSData, to address:String, onPort port:PortNumber) -> Bool {
        
        messages.append((date:NSDate(), address:address, port:port,data:data))
        udpSocket.sendData(data, toHost: address, port: port, withTimeout: -1, tag: sendTag)
        sendTag += 1
        
        do {
            try udpSocket.receiveOnce()
        }
        catch let error as NSError {
            print("error setting up receive once: \(error.localizedDescription)")
        }
        
        return true
    }

    
    // callbacks
    var didSend : (message:String, to:String, port:PortNumber, sentAt:NSDate) -> () = { _, _, _, _ in }
    var failedToSend : (message:String, to:String, port:PortNumber, sentAt:NSDate, withError:NSError?) -> () = { _, _, _, _, _ in }
    var didReceiveResponseMessage : (message:String, fromHost:String) -> () = { _, _ in }
    var didReceiveResponseJSON : (json:JSONObject, fromHost:String) -> () = { _, _ in }
}

extension UDPSender : GCDAsyncUdpSocketDelegate {
    
    func udpSocket(sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {

        let messageData = messages[tag]
        guard let message = NSString(data: messageData.3, encoding: NSUTF8StringEncoding) as? String
            else { return }
        didSend(message:message, to:messageData.1, port:messageData.2, sentAt:messageData.0)
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: NSError?) {

        let messageData = messages[tag]
        guard let message = NSString(data: messageData.3, encoding: NSUTF8StringEncoding) as? String
            else { return }
        failedToSend(message:message, to:messageData.1, port:messageData.2, sentAt:messageData.0, withError:error)
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket, didReceiveData data: NSData, fromAddress inAddress: NSData, withFilterContext filterContext: AnyObject?) {
        print("\(#function) \(data)")
        
        let address = GCDAsyncUdpSocket.hostFromAddress(inAddress)!
        
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue:0))
            didReceiveResponseJSON(json: json, fromHost:address)
            print("json: \(json)")
        }
        catch {
            
            // it's not valid json, but maybe it's a valid string
            if let message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                print("message: \(message)")
                didReceiveResponseMessage(message: message, fromHost:address)
            }
        }
    }
}