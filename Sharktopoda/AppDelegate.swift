//
//  AppDelegate.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/23/16.
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

        serverCoordinator = ServerCoordinator(videoCoordinator:videoCoordinator)
        serverCoordinator?.videoCoordinator = videoCoordinator
    
        loggingCoordinator = LoggingCoordinator()
        loggingCoordinator.storyboard = storyboard
        
        // add our coordinators to the responder chain so they can respond to 
        NSApp.nextResponder = serverCoordinator
        serverCoordinator.nextResponder = videoCoordinator
        videoCoordinator.nextResponder = loggingCoordinator
        
        // show the openURL prompt when we first load
        // this is commented out because, most of the time, this app will be controlled from an external client
        // so showing the "Open URL…" dialog might be confusing
//        videoCoordinator.openURL(self)

    }
    
}

