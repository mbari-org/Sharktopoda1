//
//  OpenURLPromptWindowController.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/23/16.
//

import Cocoa

final class OpenURLPromptWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.delegate = self
        window?.excludedFromWindowsMenu = true
    }
}

extension OpenURLPromptWindowController : NSWindowDelegate {
    
    // whenever this window is no longer the key window, it should disappear
    func windowDidResignKey(notification: NSNotification) {
        close()
    }
}
