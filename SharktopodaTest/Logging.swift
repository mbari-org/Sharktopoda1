//
//  Logging.swift
//  SharktopodaTest
//
//  Created by Joseph Wardell on 8/23/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Cocoa

//TODO: make a Logging Coordinator and move the Log window loading into it and out of the storyboard

// MARK: Logging Levels

enum LogLabel {
    case normal
    case start
    case end
    case important
    case error
    
    var textColor : NSColor {
        switch self {
        case .normal:   return NSColor(white: 0.2, alpha: 1.0)
        case .start:    return NSColor(deviceHue: 120/360, saturation: 1, brightness: 0.75, alpha: 1)   // green, but not too bright
        case .end:      return NSColor(deviceHue: 30/360, saturation: 1, brightness: 0.75, alpha: 1)  // orange, but not too bright
        case important: return NSColor.blueColor()
        case .error:    return NSColor.redColor()
        }
    }
}

// MARK:- Logging Protocol

// if you want to support logging to the UI, then adopt this protocol
protocol Logging {
    func log(message:String, label:LogLabel)
}

extension Logging {
    
    func log(message:String) {
        log(message, label:.normal)
    }
    
    func log(error:NSError) {
        log(error.localizedDescription, label:.error)
    }
}


// MARK:- Model-Level Logging Implementation

// if you want an object that logs as a parameter somewhere, then use this
final class Log : Logging {
    
    private(set) var log = NSMutableAttributedString()
    
    func log(message: String, label: LogLabel) {
        log.log(message, label: label)
        notify()
    }
    
    struct Notifications {
        static let LogChanged = "LogChanged"
    }
    
    func notify() {
        NSNotificationCenter.defaultCenter().postNotificationName(Log.Notifications.LogChanged, object: self)
    }
    
    func addListener(listener:AnyObject) {
        NSNotificationCenter.defaultCenter().addObserver(listener, selector: #selector(LogListener.logChanged(_:)), name: Log.Notifications.LogChanged, object: self)
    }
    
    func removeListener(listener:AnyObject) {
        NSNotificationCenter.defaultCenter().removeObserver(listener)
    }
}

@objc protocol LogListener {
    
    @objc func logChanged(notification:NSNotification)
}

extension LogListener {
    
    func logFromNotification(notification:NSNotification) -> Log? {
        return notification.object as? Log
    }
}

// MARK:- Cocoa Additions

extension NSMutableAttributedString : Logging {
    
    
    func log(message:String, label:LogLabel) {
        let attributedMessage = NSAttributedString(string: "\(message)\n",
                                                   attributes: [NSForegroundColorAttributeName: label.textColor]
        )
        let dateString = "\(NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .ShortStyle, timeStyle: .MediumStyle)):\t"
        appendAttributedString(NSAttributedString(string:dateString, attributes: [NSForegroundColorAttributeName: NSColor.darkGrayColor()]))
        appendAttributedString(attributedMessage)
    }
    
}

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
        // TODO: not always scrolling to the bottom
        // I think we're not rewrapping before the new scrollposition is calculated
        guard let scrollView = enclosingScrollView,
            docView = scrollView.documentView as? NSView
            else { return }
        
        let y = docView.flipped ? docView.frame.maxY : 0
        let newScrollPosition = NSPoint(x: 0, y: y)
        
        docView.scrollPoint(newScrollPosition)
    }
}


