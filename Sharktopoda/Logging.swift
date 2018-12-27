//
//  Logging.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/23/16.
//

import Cocoa

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
        case .important: return NSColor.blue
        case .error:    return NSColor.red
        }
    }
}

// MARK:- Logging Protocol

// if you want to support logging to the UI, then adopt this protocol
protocol Logging {
    func log(_ message:String, label:LogLabel)
}

extension Logging {
    
    func log(_ message:String) {
        log(message, label:.normal)
    }
    
    func log(_ error:NSError) {
        log(error.localizedDescription, label:.error)
    }
}


// MARK:- Model-Level Logging Implementation

// if you want an object that logs as a parameter somewhere, then use this
final class Log : Logging {
    
    fileprivate(set) var log = NSMutableAttributedString()
    
    var savePath : URL?
    fileprivate var saveTimer : Timer?
    
    fileprivate var writing = false
    
    func log(_ message: String, label: LogLabel, andWriteToFileAfterDelay writeDelay:TimeInterval) {
        log.log(message, label: label)
        notify()
        
        if !writing {
            // if there was a timer set up to save, then cancel it
            saveTimer?.invalidate()
            saveTimer = Timer.scheduledTimer(timeInterval: writeDelay, target: self, selector: #selector(writeLogToDisk(_:)), userInfo: nil, repeats: false)
        }
    }
    
    func log(_ message: String, label: LogLabel) {
        log(message, label: label, andWriteToFileAfterDelay: 5)
    }
    
    struct Notifications {
        static let LogChanged = "LogChanged"
    }
    
    func notify() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: Log.Notifications.LogChanged), object: self)
    }
    
    func addListener(_ listener:AnyObject) {
        NotificationCenter.default.addObserver(listener, selector: #selector(LogListener.logChanged(_:)), name: NSNotification.Name(rawValue: Log.Notifications.LogChanged), object: self)
    }
    
    func removeListener(_ listener:AnyObject) {
        NotificationCenter.default.removeObserver(listener)
    }
    
    @objc func writeLogToDisk(_:Timer) {
        guard let savePath = savePath else { return }
        guard let saveDirectory: URL = savePath.deletingLastPathComponent() else { return }
        guard !writing else { return }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
            
            let stringToWrite = self.log.string
            self.writing = true
            do {
                try FileManager.default.createDirectory(at: saveDirectory, withIntermediateDirectories: true, attributes: nil)
                try stringToWrite.write(to: savePath, atomically: true, encoding: String.Encoding.utf8)
//                print("wrote log to \(savePath)")
            }
            catch let error as NSError {
                print("error writing log to \(savePath): \(error.localizedDescription)")
            }
            self.writing = false
        }

    }
}

@objc protocol LogListener {
    
    @objc func logChanged(_ notification:Notification)
}

extension LogListener {
    
    func logFromNotification(_ notification:Notification) -> Log? {
        return notification.object as? Log
    }
}

// MARK:- Cocoa Additions

extension NSMutableAttributedString : Logging {
    
    
    func log(_ message:String, label:LogLabel) {
        let attributedMessage = NSAttributedString(string: "\(message)\n",
                                                   attributes: [NSForegroundColorAttributeName: label.textColor]
        )
        let dateString = "\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)):\t"
        append(NSAttributedString(string:dateString, attributes: [NSForegroundColorAttributeName: NSColor.darkGray]))
        append(attributedMessage)
    }
    
}



