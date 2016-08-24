//
//  AppDelegate.swift
//  SharktopodaTest
//
//  Created by Joseph Wardell on 8/23/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var serverCoordinator : ServerCoordinator?
    let videoCoordinator = VideoPlayerCoordinator()


    func applicationDidFinishLaunching(aNotification: NSNotification) {

        serverCoordinator = ServerCoordinator()
    
        // add the serverCoordinator to the responder chain so it can respond to menu items
        NSApp.nextResponder = serverCoordinator
        serverCoordinator?.nextResponder = videoCoordinator
        serverCoordinator?.videoCoordinator = videoCoordinator
        
        // show the openURL prompt when we first load
//        videoCoordinator.openURL(self)

    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

