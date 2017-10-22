//
//  Logging+AppKit.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 9/1/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import AppKit


extension NSTextView : Logging {
    
    func log(_ message:String, label:LogLabel) {
        textStorage?.log(message, label: label)
        scrollToBottom()
    }
    
    func showLog(_ log:NSAttributedString) {
        
        textStorage?.setAttributedString(log)
        scrollToBottom()
    }
    
    func showLog(_ log:Log) {
        
        showLog(log.log)
    }
    
    fileprivate func scrollToBottom() {
        // NOTE: not always scrolling to the bottom
        // I think we're not rewrapping before the new scrollposition is calculated
        guard let scrollView = enclosingScrollView,
            let docView = scrollView.documentView
            else { return }
        
        let y = docView.isFlipped ? docView.frame.maxY : 0
        let newScrollPosition = NSPoint(x: 0, y: y)
        
        docView.scroll(newScrollPosition)
    }
}
