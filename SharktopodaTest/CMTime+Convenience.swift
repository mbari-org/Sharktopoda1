//
//  CMTime+Convenience.swift
//  SharktopodaTest
//
//  Created by Joseph Wardell on 8/26/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation
import CoreMedia

extension CMTime {
    
    // TODO: I'd love to have this as an init rather than a factory method, much swiftier
    static func timeWithMilliseconds(milliseconds:UInt) -> CMTime {
        let seconds = Double(milliseconds)/1000
        let out = CMTime(seconds:seconds, preferredTimescale:1000)
        return out
    }
    
    var milliseconds : UInt {
        return UInt(seconds * 1000)
    }
    
    var halftime : CMTime {
        return CMTimeMultiplyByRatio(self, 1, 2)
    }
}
