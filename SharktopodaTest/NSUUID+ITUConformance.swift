//
//  NSUUID+ITUConformance.swift
//  SharktopodaTest
//
//  Created by Joseph Wardell on 8/27/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation


extension NSUUID {
    
    // a variant of the string form of the NSUUIN that conforms to ITU requirements.
    // in particular, section 6.5.4 that a human-readable identifier must be lowercase
    // see http://www.itu.int/rec/T-REC-X.667/en
    var ITUString : String {
        return UUIDString.lowercaseString
    }
}