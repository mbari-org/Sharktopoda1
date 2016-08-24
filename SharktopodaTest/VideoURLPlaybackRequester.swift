//
//  NSResponder+OtherActions.swift
//  AVPlayerTest
//
//  Created by Joseph Wardell on 8/23/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Cocoa

/*
 Some types that help maintain the abstractin between the controller and coordinator layers
 */

@objc protocol VideoURLPlaybackRequester {
    
    // NOTE: the url is requested as a string
    // the playback requester is not expected to necessarily have a valid NSURL
    // the playback object will
    var urlToPlay : String { get }
}



@objc protocol VideoPlaybackCoordinator {
    
    // the action that a VideoURLPlaybackRequester would call for
    @objc func openURLForPlayback(sender:AnyObject)
}

extension VideoURLPlaybackRequester {
    
    func requestPlayback() {
        
        NSApp.sendAction(#selector(VideoPlaybackCoordinator.openURLForPlayback(_:)), to: nil, from: self)
    }
}