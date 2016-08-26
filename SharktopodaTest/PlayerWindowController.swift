//
//  PlayerWindowController.swift
//  AVPlayerTest
//
//  Created by Joseph Wardell on 8/23/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Cocoa

final class PlayerWindowController: NSWindowController {

    var playerViewController : PlayerViewController {
        return contentViewController as! PlayerViewController
    }
    
    var videoURL : NSURL? {
        get {
            return playerViewController.videoURL
        }
        set {
            playerViewController.videoURL = newValue
        }
    }
    
    var uuid : NSUUID?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.appearance = NSAppearance(named:NSAppearanceNameVibrantDark)
    }
    
    override func showWindow(sender: AnyObject?) {
        
        window?.setContentSize(NSSize(width: 377, height: 34))
        window?.center()

        super.showWindow(sender)
    }
}
