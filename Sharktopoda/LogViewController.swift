//
//  LogViewController.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/22/16.
//

import Cocoa

final class LogViewController: MessageHandlerViewController {

    @IBOutlet var logView: NSTextView! {
        didSet {
            logView.isEditable = false
        }
    }

    override var messageHandler : MessageHandler? {
        willSet {
            messageHandler?.log.removeListener(self)
        }
        didSet {
            if let messageHandler = messageHandler {
                logView.showLog(messageHandler.log)
                messageHandler.log.addListener(self)
            }
        }
    }    
}

extension LogViewController : LogListener {
    
    func logChanged(_ notification: Notification) {
        guard let log = logFromNotification(notification) else { return }
        guard let messageHandler = messageHandler else { return }
        guard log === messageHandler.log else { return }
        
        logView.showLog(log.log)
    }
}
