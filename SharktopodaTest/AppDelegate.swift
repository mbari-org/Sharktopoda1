//
//  AppDelegate.swift
//  SharktopodaTest
//
//  Created by Joseph Wardell on 8/23/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Cocoa

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {

    var serverCoordinator : ServerCoordinator!
    var videoCoordinator : VideoPlayerCoordinator!
    var loggingCoordinator : LoggingCoordinator!

    struct StoryboardIdentifiers {
        static let StoryboardName = "Main"
    }
    
    lazy var storyboard = {
        return NSStoryboard(name: StoryboardIdentifiers.StoryboardName, bundle: nil)
    }()

    func applicationDidFinishLaunching(aNotification: NSNotification) {

        videoCoordinator = VideoPlayerCoordinator()
        videoCoordinator.storyboard = storyboard

        serverCoordinator = ServerCoordinator()
        serverCoordinator?.videoCoordinator = videoCoordinator
    
        loggingCoordinator = LoggingCoordinator()
        loggingCoordinator.storyboard = storyboard
        
        // add our coordinators to the responder chain so they can respond to 
        NSApp.nextResponder = serverCoordinator
        serverCoordinator.nextResponder = videoCoordinator
        videoCoordinator.nextResponder = loggingCoordinator
        
        // show the openURL prompt when we first load
//        videoCoordinator.openURL(self)

    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

