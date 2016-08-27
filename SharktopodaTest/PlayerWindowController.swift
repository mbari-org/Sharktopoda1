//
//  PlayerWindowController.swift
//  AVPlayerTest
//
//  Created by Joseph Wardell on 8/23/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Cocoa

protocol PlayerWindowControllerDelegate {
    
    func playerWindowWillClose(notification: NSNotification)
    func playerWindowDidBecomeMain(notification: NSNotification)
}

final class PlayerWindowController: NSWindowController {

    var delegate : PlayerWindowControllerDelegate?
    
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
        
        playerViewController.addObserver(self, forKeyPath: "title", options: NSKeyValueObservingOptions(), context: nil)
        playerViewController.mediaSizeChanged = { newSize in
            self.window?.setContentSize(newSize)
            self.window?.center()
        }
        playerViewController.readyToShowVideo = {
            self.showWindow(self)
        }
        playerViewController.failedToLoad = {
            self.close()
        }
        
        window?.delegate = self
        print("window.delegate: \(window?.delegate)")
    }
    
    
    override func showWindow(sender: AnyObject?) {
        
        print("window.delegate: \(window?.delegate)")

        window?.setContentSize(NSSize(width: 377, height: 34))
        window?.center()

        super.showWindow(sender)
    }
    
    // MARK:- KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        switch keyPath! {
            case "title":
            window?.title = playerViewController.title ?? "Unknwon"
        default:
            break
        }
    }

    
    // MARK:- External Methods

    
    func showVideo() {
        playerViewController.openVideo()
    }
}


extension PlayerWindowController : NSWindowDelegate {
    
    func windowWillClose(notification: NSNotification) {
        
        playerViewController.removeObserver(self, forKeyPath: "title")

        delegate?.playerWindowWillClose(notification)
    }
    
    func windowDidBecomeKey(notification: NSNotification) {
        delegate?.playerWindowDidBecomeMain(notification)
    }
}
