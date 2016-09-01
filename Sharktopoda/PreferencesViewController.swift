//
//  PreferencesViewController.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/22/16.
//

import Cocoa

final class PreferencesViewController: MessageHandlerViewController {

    @IBOutlet weak var portField: NSTextField!
    @IBOutlet weak var startStopButton: NSButton!
    @IBOutlet weak var errorLabel: NSTextField!

    private var preferredServerPort : UInt16 {
        
        return UInt16(portField.intValue)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        startStopButton.target = self
        startStopButton.action = #selector(startStopButtonPressed(_:))

        portField.target = self
        portField.action = #selector(takePortNumberFrom(_:))
        
        class RestrictiveNumberFormatter : NSNumberFormatter {
            override func isPartialStringValid(partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
                guard !partialString.isEmpty else { return true }
                
                guard let out = Int(partialString) else { return false }
                
                return out <= Int(PortNumber.max)
            }
        }
        portField.formatter = RestrictiveNumberFormatter()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateUI()
        errorLabel.stringValue = ""
        startStopButton.intValue = messageHandler!.server.running ? 1 : 0

        let port = messageHandler!.server.running ? (messageHandler!.server.port ?? 0) : NSUserDefaults.standardUserDefaults().preferredServerPort
        portField.stringValue = "\(port)"
        portField.becomeFirstResponder()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageHandlerDidStart(_:)),
                                                         name: MessageHandler.Notifications.DidStartListening,
                                                         object: messageHandler)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageHandlerDidStop(_:)),
                                                         name: MessageHandler.Notifications.DidStopListening,
                                                         object: messageHandler)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageHandlerDidFailToStart(_:)),
                                                         name: MessageHandler.Notifications.DidFailToStartListening,
                                                         object: messageHandler)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK:- Updating UI
    
    func updateUI() {

        portField.enabled = !messageHandler!.server.running
    }

    // MARK:- Actions

    @IBAction func startStopButtonPressed(sender:NSButton) {
        
        NSUserDefaults.standardUserDefaults().preferredServerPort = preferredServerPort
        
        messageHandler?.toggleServerOnPort(preferredServerPort)
        
        NSUserDefaults.standardUserDefaults().startServerOnStartup = sender.integerValue != 0
    }
    
    @IBAction func takePortNumberFrom(sender:AnyObject) {
        
        guard let sender = sender as? NSControl else { return }
        
        let newPort = PortNumber(sender.intValue)
        guard newPort <= PortNumber.max else { return }
        
        messageHandler?.startServerOnPort(newPort)

        NSUserDefaults.standardUserDefaults().preferredServerPort = preferredServerPort

        // user started the server from the Preference Window,
        // probably expects the server to run automatically
        // the next time it starts
        NSUserDefaults.standardUserDefaults().startServerOnStartup = true
        
    }

    
    // MARK:- Notifications

    func messageHandlerDidStart(notification:NSNotification) {
        updateUI()
        errorLabel.stringValue = ""
        startStopButton.intValue = messageHandler!.server.running ? 1 : 0
    }
    func messageHandlerDidStop(notification:NSNotification) {
        updateUI()
        errorLabel.stringValue = ""
        startStopButton.intValue = messageHandler!.server.running ? 1 : 0
        portField.becomeFirstResponder()
    }
    
    func messageHandlerDidFailToStart(notification:NSNotification) {
        guard let error = notification.userInfo?["error"] as? NSError else { return }
        errorLabel.stringValue = error.userInfo[NSLocalizedDescriptionKey] as? String ?? ""
        startStopButton.intValue = messageHandler!.server.running ? 1 : 0
        portField.becomeFirstResponder()
   }

}
