//
//  UDPSender.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/21/16.
//

import Foundation
import CocoaAsyncSocket

/*
 This is an object that can send messages via UDP
 It maintains a dictionary of messages sent and the times they were sent 
 and notifies client code via callbacks
 */
class UDPSender: NSObject {

    fileprivate var q : DispatchQueue = DispatchQueue.main
    
    fileprivate lazy var udpSocket : GCDAsyncUdpSocket = {
        return GCDAsyncUdpSocket(delegate: self, delegateQueue: self.q)
    }()

    var sendTag : Int = 0
    var messages : [(date:Date,address:String,port:PortNumber,data:Data)] = []
    
    func sendMessage(_ message:String, to address:String, onPort port:PortNumber) -> Bool {
        guard let data = message.data(using: String.Encoding.utf8) else { return false }

        sendData(data, to: address, onPort: port)
        
        return true
    }
    
    func sendData(_ data:Data, to address:String, onPort port:PortNumber) -> Bool {
        
        messages.append((date:Date(), address:address, port:port,data:data))
        udpSocket.send(data, toHost: address, port: port, withTimeout: -1, tag: sendTag)
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
    var didSend : (_ message:String, _ to:String, _ port:PortNumber, _ sentAt:Date) -> () = { _, _, _, _ in }
    var failedToSend : (_ message:String, _ to:String, _ port:PortNumber, _ sentAt:Date, _ withError:NSError?) -> () = { _, _, _, _, _ in }
    var didReceiveResponseMessage : (_ message:String, _ fromHost:String) -> () = { _, _ in }
    var didReceiveResponseJSON : (_ json:JSONObject, _ fromHost:String) -> () = { _, _ in }
}

extension UDPSender : GCDAsyncUdpSocketDelegate {
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {

        let messageData = messages[tag]
        guard let message = NSString(data: messageData.3, encoding: String.Encoding.utf8.rawValue) as? String
            else { return }
        didSend(message, messageData.1, messageData.2, messageData.0)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: NSError?) {

        let messageData = messages[tag]
        guard let message = NSString(data: messageData.3, encoding: String.Encoding.utf8.rawValue) as? String
            else { return }
        failedToSend(message, messageData.1, messageData.2, messageData.0, error)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress inAddress: Data, withFilterContext filterContext: AnyObject?) {
        print("\(#function) \(data)")
        
        let address = GCDAsyncUdpSocket.host(fromAddress: inAddress)!
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue:0))
            didReceiveResponseJSON(json as JSONObject, address)
            print("json: \(json)")
        }
        catch {
            
            // it's not valid json, but maybe it's a valid string
            if let message = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String {
                print("message: \(message)")
                didReceiveResponseMessage(message, address)
            }
        }
    }
}
