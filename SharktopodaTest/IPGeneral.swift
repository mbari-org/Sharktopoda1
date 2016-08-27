//
//  IPGeneral.swift
//  UDPServerTest
//
//  Created by Joseph Wardell on 8/21/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Foundation

typealias PortNumber = UInt16


struct NetworkingDefaults {
    struct Ports {
        // the port on which messages are sent back from the server
        // if we were using the connect as a handshake, then we would not use this
//        static let returnPort : UInt16 = 3000
    }

}