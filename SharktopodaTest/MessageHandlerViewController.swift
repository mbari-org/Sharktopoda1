//
//  MessageHandlerViewController.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/22/16.
//

import Cocoa

/*
 A View Controller that holds a MessageHandler as its representedobject.
 
 It's an abstract base class that other view controllers inherit from.
 */
class MessageHandlerViewController: NSViewController {

    var messageHandler : MessageHandler?
    
    override var representedObject: AnyObject? {
        get {
            return self.messageHandler
        }
        set {
            guard let msh = newValue as? MessageHandler else { return }
            self.messageHandler = msh
            didSetMessageHandler()
        }
    }
    
    func didSetMessageHandler() {
        // subclasses override
    }

    
    struct Notifications {
        static let DidLoad = "MessageHandlerViewControllerDidLoad"
        static let WillAppear = "MessageHandlerViewControllerWillAppear"
        static let DidAppear = "MessageHandlerViewControllerDidAppear"
        static let WillDisappear = "MessageHandlerViewControllerWillDisappear"
        static let DidDisappear = "MessageHandlerViewControllerDidDisappear"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidLoad, object: self)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.WillAppear, object: self)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidAppear, object: self)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.WillDisappear, object: self)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidDisappear, object: self)
    }
    
}
