//
//  PlayerWindowController.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/23/16.
//

import Cocoa

protocol PlayerWindowControllerDelegate {
    
    func playerWindowWillClose(_ notification: Notification)
    func playerWindowDidAppear(_ notification: Notification)
    func playerWindowDidBecomeMain(_ notification: Notification)
}

final class PlayerWindowController: NSWindowController {

    var delegate : PlayerWindowControllerDelegate?
    
    var playerViewController : PlayerViewController {
        return contentViewController as! PlayerViewController
    }
    
    var videoURL : URL? {
        get {
            return playerViewController.videoURL
        }
        set {
            playerViewController.videoURL = newValue! as NSURL as URL
        }
    }
    
    var uuid : UUID?
    
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
    }
    
    
    override func showWindow(_ sender: Any?) {
        
        super.showWindow(sender)

        delegate?.playerWindowDidAppear(Notification(name: Notification.Name(rawValue: "PlayerWindowController.didAppear"), object: self.window))
    }
    
    // MARK:- KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

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
    
    func windowWillClose(_ notification: Notification) {
        
        playerViewController.removeObserver(self, forKeyPath: "title")

        delegate?.playerWindowWillClose(notification)
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
        delegate?.playerWindowDidBecomeMain(notification)
    }
}
