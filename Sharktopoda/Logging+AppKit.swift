//
//  Logging+AppKit.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 9/1/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import AppKit


extension NSTextView : Logging {
    
    func log(message:String, label:LogLabel) {
        textStorage?.log(message, label: label)
        scrollToBottom()
    }
    
    func showLog(log:NSAttributedString) {
        
        textStorage?.setAttributedString(log)
        scrollToBottom()
    }
    
    func showLog(log:Log) {
        
        showLog(log.log)
    }
    
    private func scrollToBottom() {
        // NOTE: not always scrolling to the bottom
        // I think we're not rewrapping before the new scrollposition is calculated
        guard let scrollView = enclosingScrollView,
            docView = scrollView.documentView
            else { return }
        
        let y = docView.flipped ? docView.frame.maxY : 0
        let newScrollPosition = NSPoint(x: 0, y: y)
        
        docView.scrollPoint(newScrollPosition)
    }
}
