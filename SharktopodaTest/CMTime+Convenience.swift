//
//  CMTime+Convenience.swift
//  SharktopodaTest
//
//  Created by Joseph Wardell on 8/26/16.
//

import Foundation
import CoreMedia

extension CMTime {
    
    // NOTE: I'd love to have this as an init rather than a factory method, much swiftier
    // but the compiler complains when I try
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
