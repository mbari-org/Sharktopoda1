//
//  MessageHandlerViewController.swift
//  Sharktopoda
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
    
    override var representedObject: Any? {
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
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.DidLoad), object: self)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.WillAppear), object: self)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.DidAppear), object: self)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.WillDisappear), object: self)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.DidDisappear), object: self)
    }
    
}
