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

    fileprivate var preferredServerPort : UInt16 {
        
        return UInt16(portField.intValue)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        startStopButton.target = self
        startStopButton.action = #selector(startStopButtonPressed(_:))

        portField.target = self
        portField.action = #selector(takePortNumberFrom(_:))
        
        class RestrictiveNumberFormatter : NumberFormatter {
            override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<AutoreleasingUnsafeMutablePointer<NSString?>>?, errorDescription error: AutoreleasingUnsafeMutablePointer<AutoreleasingUnsafeMutablePointer<NSString?>>?) -> Bool {
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

        let port = messageHandler!.server.running ? (messageHandler!.server.port ?? 0) : UserDefaults.standard.preferredServerPort
        portField.stringValue = "\(port)"
        portField.becomeFirstResponder()

        NotificationCenter.default.addObserver(self, selector: #selector(messageHandlerDidStart(_:)),
                                                         name: NSNotification.Name(rawValue: MessageHandler.Notifications.DidStartListening),
                                                         object: messageHandler)
        NotificationCenter.default.addObserver(self, selector: #selector(messageHandlerDidStop(_:)),
                                                         name: NSNotification.Name(rawValue: MessageHandler.Notifications.DidStopListening),
                                                         object: messageHandler)
        NotificationCenter.default.addObserver(self, selector: #selector(messageHandlerDidFailToStart(_:)),
                                                         name: NSNotification.Name(rawValue: MessageHandler.Notifications.DidFailToStartListening),
                                                         object: messageHandler)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        NotificationCenter.default.removeObserver(self)
    }

    // MARK:- Updating UI
    
    func updateUI() {

        portField.isEnabled = !messageHandler!.server.running
    }

    // MARK:- Actions

    @IBAction func startStopButtonPressed(_ sender:NSButton) {
        
        UserDefaults.standard.preferredServerPort = preferredServerPort
        
        messageHandler?.toggleServerOnPort(preferredServerPort)
        
        UserDefaults.standard.startServerOnStartup = sender.integerValue != 0
    }
    
    @IBAction func takePortNumberFrom(_ sender:AnyObject) {
        
        guard let sender = sender as? NSControl else { return }
        
        let newPort = PortNumber(sender.intValue)
        guard newPort <= PortNumber.max else { return }
        
        messageHandler?.startServerOnPort(newPort)

        UserDefaults.standard.preferredServerPort = preferredServerPort

        // user started the server from the Preference Window,
        // probably expects the server to run automatically
        // the next time it starts
        UserDefaults.standard.startServerOnStartup = true
        
    }

    
    // MARK:- Notifications

    func messageHandlerDidStart(_ notification:Notification) {
        updateUI()
        errorLabel.stringValue = ""
        startStopButton.intValue = messageHandler!.server.running ? 1 : 0
    }
    func messageHandlerDidStop(_ notification:Notification) {
        updateUI()
        errorLabel.stringValue = ""
        startStopButton.intValue = messageHandler!.server.running ? 1 : 0
        portField.becomeFirstResponder()
    }
    
    func messageHandlerDidFailToStart(_ notification:Notification) {
        guard let error = notification.userInfo?["error"] as? NSError else { return }
        errorLabel.stringValue = error.userInfo[NSLocalizedDescriptionKey] as? String ?? ""
        startStopButton.intValue = messageHandler!.server.running ? 1 : 0
        portField.becomeFirstResponder()
   }

}
