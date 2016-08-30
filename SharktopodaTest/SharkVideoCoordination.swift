//
//  SharkVideoCoordination.swift
//  AVPlayerTest
//
//  Created by Joseph Wardell on 8/23/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation
import CoreMedia

////    playing is when the video is playing at a rate of 1.0
////    shuttling forward is when the video is playing with a positive rate that is not equal to 1.0
////    shuttling reverse is when the video is playing with a negative rate.
////    paused is obvious. (Not playing)
enum SharkVideoPlaybackStatus : String {
    case playing
    case shuttlingForward = "shuttling forward"
    case shuttlingInReverse = "shuttling reverse"
    case paused
}

/*
 The protocol that must be supported by a coordinator in order to implement the Sharktopoda API
 These methods from the Server Coordinator
 */

protocol SharkVideoCoordination {
    
    // video loading requires some asynchronicity as the video file is loaded from disk or ther network
    // so we need a callback to be called after the video load has succeeded or failed
    // if success is false, then you should expect error to not be nil
    func openVideoAtURL(url:NSURL, usingUUID uuid:NSUUID, callback:(success:Bool, error:NSError?) -> ())

    // note: all of these methods are marked as throws
    // because they can be called by the ServerCoordinator
    // which will want to handle all errors the same way

    func closeWindowForVideoWithUUID(uuid inUUID:NSUUID) throws
    
    ////    Request Video Information for a Specific Window
    // (sperated into two methods for 2 slightly different use cases)
    func returnInfoForVideoWithUUID(uuid:NSUUID) throws -> [String:AnyObject]
    ////    It should return the UUID and URL of the currently focused (or top most in z order)
    func returnInfoForFrontmostVideo() throws -> [String:AnyObject]
    
    ////    Request information for all open videos
    func returnAllVideoInfo() throws -> [[String:AnyObject]]
    
    ////    Focuses the window containing the video with the given UUID
    func focusWindowForVideoWithUUID(uuid inUUID:NSUUID) throws
    
    ////    Play the video associated with the UUID. The play rate will be 1.0
    ////    Optionally the play command can contain a rate for the playback. A positive rate is forward, negative is reverse.
    func playVideoWithUUID(uuid inUUID:NSUUID, rate:Double) throws
    
    ////    Pauses the playback for the video specified by the UUID
    func pauseVideoWithUUID(uuid inUUID:NSUUID) throws
    
    ////    Request Status
    ////
    ////    Return the current playback status of the video (by UUID). Possible responses include: shuttling forward, shuttling reverse, paused, playing, not found.
    ////
    func requestPlaybackStatusForVideoWithUUID(uuid inUUID:NSUUID) throws -> SharkVideoPlaybackStatus

    ////    Request elapsed time
    ////
    ////    Return the elapsed time (from the start) of the video as milliseconds.
    func requestElapsedTimeForVideoWithUUID(uuid inUUID:NSUUID) throws -> UInt 

    ////    Seek Elapsed Time
    ////
    ////    Seek to the provided elapsed time (which will be in milliseconds)
    //      returns the actual time advanced to after the advance was done
    func advanceToTimeInMilliseconds(time: UInt, forVideoWithUUID inUUID: NSUUID) throws

    
    ////    Framecapture
    ////
    ////    Sharktopoda should immediately grab the current frame from the video along with the elapsed time of that frame. The image should be saved (in a separate non-blocking thread. I think this is the default in AVFoundation). This action should not interfere with video playback.
    ////    When the image has been written to disk it should respond via the remote UDP port specified in the connect command with:
    ////    The status field should be "failed" if Sharktopus is unable to capture and write the image to disk.
    func captureCurrentFrameForVideWithUUID(uuid inUUID:NSUUID, andSaveTo saveLocation:NSURL, referenceUUID:NSUUID,
                                                 then callback:(success:Bool, error:NSError?, requestedTimeInMilliseconds:UInt?, actualTimeInMilliseconds:UInt?)->()) throws

    ////    Advance the video one frame for the given video The UDP/JSON command is
    // we'll just make it a generic frame count to advance
    func advanceToNextFrameInVideoWithUUID(uuid inUUID:NSUUID, byFrameCount:Int) throws
 
}