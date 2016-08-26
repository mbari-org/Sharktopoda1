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
    
    var milliseconds : UInt {
        return UInt(seconds * 1000)
    }
}
