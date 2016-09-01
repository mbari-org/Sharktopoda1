//
//  LoggingCoordinator.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/25/16.
//

import Cocoa

/*
 Ties the Logging system into the command chain.
 Provides a window for showing logs.
 */
class LoggingCoordinator: NSResponder {

    struct StoryboardIdentifiers {
        static let LogViewWindowController = "LogViewWindowController"
    }

    var storyboard : NSStoryboard!
    var logViewController : LogViewController?  // as of right now, this isn't used, but who knows?
    
    lazy var logViewWindowController : NSWindowController = {
        
        var out = self.storyboard.instantiateControllerWithIdentifier(StoryboardIdentifiers.LogViewWindowController) as! NSWindowController
        self.logViewController = out.contentViewController as? LogViewController
        return out
    }()
    

    // MARK:- Actions
    
    @IBAction func showLogWindow(sender:AnyObject) {
        
        if !(logViewWindowController.window?.visible ?? false) {
            logViewWindowController.showWindow(sender)
        }
        logViewWindowController.window?.makeKeyAndOrderFront(sender)
    }
}
