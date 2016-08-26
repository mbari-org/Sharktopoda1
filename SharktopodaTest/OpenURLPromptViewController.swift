//
//  ViewController.swift
//  AVPlayerTest
//
//  Created by Joseph Wardell on 8/22/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Cocoa

final class OpenURLPromptViewController: NSViewController {

    @IBOutlet weak var urlField: NSTextField!

    override var representedObject: AnyObject? {
        didSet {
            if let rep = representedObject as? CustomStringConvertible {
                requestedURL = rep.description
            }
            else {
                requestedURL = ""
            }
        }
    }
    
    var requestedURL : String? {
        get {
            return urlField.stringValue
        }
        set {
            urlField.stringValue = newValue ?? ""
            representedObject = urlField.stringValue
        }
    }
    
    @IBAction func openUserSelectedURL(sender:NSButton) {
        
        requestPlayback()
        
        NSApp.sendAction(#selector(NSWindow.performClose(_:)), to: nil, from: self)
    }
}

extension OpenURLPromptViewController : VideoURLPlaybackRequester {
    var urlToPlay: String {
        return requestedURL ?? ""
    }
}

