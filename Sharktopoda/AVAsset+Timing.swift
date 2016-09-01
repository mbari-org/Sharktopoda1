//
//  AVAsset+Timing.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/27/16.
//

import Foundation
import AVFoundation

extension AVAsset {
    
    var frameDuration : CMTime? {
        
        let visualTracks = tracksWithMediaCharacteristic(AVMediaCharacteristicVisual)
        guard visualTracks.count > 0 else { return nil }
        return visualTracks.first!.minFrameDuration
    }
    
    // the closeest resolution that makes sense is 1/2 the minimum duration of any frame
    // for simplicity, we assume only one video track
    var minSeekTolerance : CMTime? {
        
        let visualTracks = tracksWithMediaCharacteristic(AVMediaCharacteristicVisual)
        guard visualTracks.count > 0 else { return nil }
        return visualTracks.first!.minFrameDuration.halftime
    }
    
}