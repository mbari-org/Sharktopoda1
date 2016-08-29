//
//  AVAsset+Timing.swift
//  SharktopodaTest
//
//  Created by Joseph Wardell on 8/27/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAsset {
    
    // the closeest resolution that makes sense is 1/2 the minimum duration of any frame
    // for simplicity, we assume only one video track
    var minSeekTolerance : CMTime? {
        
        let visualTracks = tracksWithMediaCharacteristic(AVMediaCharacteristicVisual)
        guard visualTracks.count > 0 else { return nil }
        return visualTracks.first!.minFrameDuration.halftime
    }
    
}