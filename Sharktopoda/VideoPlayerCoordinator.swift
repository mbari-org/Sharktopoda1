//
//  VideoPlayerCoordinator.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/23/16.
//

import Cocoa

/*
 Coordinates video playback through a group of window controllers.
 Basically, handles the video playback aspect of the app
 And handles responding to commands from the Networking layer
 */
final class VideoPlayerCoordinator: NSResponder, VideoPlaybackCoordinator{
    
    
    struct StoryboardIdentifiers {
        static let OpenURLWindowController = "OpenURLWindowController"
        static let VideoPlayerWindowController = "VideoPlayerWindowController"
        static let TestingPanelWindowController = "TestingPanelWindowController"
    }
    
    var storyboard : NSStoryboard!
    
    lazy var openURLPromptWindowController : NSWindowController = {
        return self.storyboard.instantiateController(withIdentifier: StoryboardIdentifiers.OpenURLWindowController) as! NSWindowController
    }()
    
    // matches player controllers to their UUID
    // this allows us to access videos by UUID
    // and maintain the lifetime of the players
    var videoPlayerWindowControllers = [UUID:PlayerWindowController]()
    
    // the frontmost video player window controller, for when a client asks for info about the frontmost video
    var frontmostPlayerWindowController : PlayerWindowController?
    
    // a dictionary matching UUIDs to callbacks, for when we're told to capture frames
    typealias frameCaptureCallback = (_ success:Bool, _ error:NSError?, _ requestedTimeInMilliseconds:UInt?, _ actualTimeInMilliseconds:UInt?)->()
    var frameCaptureCallbacks = [UUID:(frameCaptureCallback)]()

    
    // MARK:- Actions
    
    // shows the openURL window
    @IBAction func openURL(_ sender:AnyObject) {
        
        openURLPromptWindowController.window?.center()
        openURLPromptWindowController.showWindow(self)
    }
    
    // sent by a client class,
    // ask client for an URL to play back, then validate it and show a video player window
    @IBAction func openURLForPlayback(_ sender:AnyObject) {
        
        guard let requester = sender as? VideoURLPlaybackRequester else { return }
        let possibleURL = requester.urlToPlay
        
        if let url = URL(string:possibleURL) {
            self.openVideoAtURL(url, usingUUID:UUID()) { (success, error) in
                
                if !success {
                    DispatchQueue.main.async {
                        
                        let alert = NSAlert()
                        alert.messageText = "Failed to Load Video"
                        alert.informativeText = "Could not load video at \(url.description )\n\nerror:\(error!.localizedDescription ?? "unknown")"
                        alert.runModal()
                    }
                }
            }
        }
        // otherwise, do nothing...
    }
    
    // shows an NSOpenPanel and lets the user choose one video file to play
    @IBAction func openDocument(_ sender:AnyObject) {
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["public.audiovisual-content"]
        
        openPanel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                if let url = openPanel.url {
                    
                    self.openVideoAtURL(url, usingUUID:UUID()) { (success, error) in
                        
                        if !success {
                            DispatchQueue.main.async {
                                
                                let alert = NSAlert()
                                alert.messageText = "Failed to Load Video"
                                alert.informativeText = "Could not load video at \(url.description ?? "unknown")\n\nerror:\(error!.localizedDescription ?? "unknown")"
                                alert.runModal()
                            }

                        }
                    }
                }
            }
        }
    }
    
    #if false
    // these methods are for testing purposes.
    // Check out the AVPlayerTest project to see them in use
    lazy var testWindowController : TestWindowController = {
        
        var out = self.storyboard.instantiateControllerWithIdentifier(StoryboardIdentifiers.TestingPanelWindowController) as! TestWindowController
        out.testViewController.coordinator = self
        return out
    }()
    
    @IBAction func showTestWindow(sender:AnyObject) {
        
        testWindowController.showWindow(self)
    }
    #endif
    
    // MARK:- URL Validation
    
    enum URLValidation {
        case url(URL)
        case error(NSError)
    }
    
    func validateURLSchemeForURL(_ url:URL) -> URLValidation {
        
        // only accept http and file urls
        guard ["file", "http", "https"].contains(url.scheme!) else {
            return .error(errorWithCode(.unsupportedURL, description:"The url \(url) is not supported"))
        }
        return .url(url)
    }
    
    func validateURL(_ url:URL) -> URLValidation {
        
        // only accept http and file urls
        
        // first, validate the scheme
        let validURL = validateURLSchemeForURL(url)
        switch validURL {
        case .error:
            return validURL
            
        case .url:
            // if it's a file url, make sure it represents a reachable resource
            if "file" == url.scheme {
                var error : NSError?
                if !(url as NSURL).checkResourceIsReachableAndReturnError(&error) {
                    return .error(error!)
                }
            }
            
            return .url(url)
        }
    }
    
    
    // MARK:- Introspection of videos
    
    func playerWindowControllerForUUID(_ uuid:UUID) throws -> PlayerWindowController {
        guard let out = videoPlayerWindowControllers[uuid] else {
            throw(errorWithCode(.noVideoForThisUUID, description: "No video is available with UUID \(uuid.uuidString)"))
        }
        
        return out
    }
    
    func infoForVideoWithUUID(_ uuid:UUID) throws -> (url:URL, uuid:UUID) {
        let pwc = try playerWindowControllerForUUID(uuid)
        
        guard let url = pwc.videoURL else {
            throw(errorWithCode(.noURLForThisUUID, description: "No url associated with video with UUID \(uuid.uuidString)"))
        }
        guard uuid == pwc.uuid else {
            throw(errorWithCode(.bizarreInconsistency, description: "Bizarre inconsistency at \(#file):\(#line)"))
        }
        
        return (url as URL, uuid)
    }
    
    // MARK:- Utility
    
    func errorWithCode(_ code:ErrorCode, description:String) -> NSError {
        return NSError(domain: "VideoPlayerCoordinator", code: code.rawValue,
                       userInfo: [NSLocalizedDescriptionKey:description])
    }
    
}


// MARK:- SharkVideoCoordination

extension VideoPlayerCoordinator : SharkVideoCoordination {
    

    // MARK:- SharkVideoCoordination:Video Playback
    
    // the main function that validates and then shows a video given an URL
    // this is the method that is called no matter how a video url is chosen (via open dialog, via openURL window, or via network)
    func openVideoAtURL(_ url: URL, usingUUID uuid: UUID, callback: @escaping (Bool, NSError?) -> ()) {
        switch validateURL(url) {
        case .error(let error):
            callback(false, error)
            return
        default:
            break
        }
        
        let playerWC = self.storyboard.instantiateController(withIdentifier: "VideoPlayerWindowController") as! PlayerWindowController
        playerWC.uuid = uuid
        playerWC.videoURL = url
        playerWC.delegate = self
        
        let playerVC = playerWC.playerViewController
        playerVC.videoLoadCompletionCallback = callback
        playerVC.frameGrabbingCallback = receivedFrameGrabbingOutcome
        
        playerWC.showVideo()
        
        videoPlayerWindowControllers[uuid] = playerWC
    }
    
    
    // MARK:- SharkVideoCoordination:Video Info
    
    
    func returnInfoForVideoWithUUID(_ uuid:UUID) throws -> [String:AnyObject] {
        
        let info = try infoForVideoWithUUID(uuid)
        return ["url":info.url as AnyObject, "uuid":info.uuid as AnyObject]
    }
    
    func returnInfoForFrontmostVideo() throws -> [String : AnyObject] {
        
        guard let frontpwc = frontmostPlayerWindowController else {
            throw(errorWithCode(.focusedVideoWindowDoesNotExist, description: "There is no focused video window"))
        }
        
        guard let uuid = frontpwc.uuid else {
            throw(errorWithCode(.bizarreInconsistency, description: "Bizarre inconsistency at \(#file):\(#line)"))
        }
        
        return try returnInfoForVideoWithUUID(uuid as UUID)
    }
    
    func returnAllVideoInfo() throws -> [[String:AnyObject]] {
        
        var out = [[String:AnyObject]]()
        
        for (thisUUID, _) in videoPlayerWindowControllers {
            let (thisURL, _) = try infoForVideoWithUUID(thisUUID)
            out.append(["url":thisURL.description as AnyObject, "uuid":thisUUID.uuidString as AnyObject])
        }
        return out
    }
    
    func requestPlaybackStatusForVideoWithUUID(uuid inUUID:UUID) throws -> SharkVideoPlaybackStatus {
        
        let pwc = try playerWindowControllerForUUID(inUUID)
        
        switch pwc.playerViewController.videoPlaybackRate {
        case 1.0:
            return .playing
        case let (x) where x < 0:
            return .shuttlingInReverse
        case let x where x > 0:
            return .shuttlingForward
        default:
            return .paused
        }
    }
    
    func requestElapsedTimeForVideoWithUUID(uuid inUUID:UUID) throws -> UInt  {
        let pwc = try playerWindowControllerForUUID(inUUID)
        
        return pwc.playerViewController.videoElpasedTimeInMilliseconds
    }

    func advanceToTimeInMilliseconds(_ time: UInt, forVideoWithUUID inUUID: UUID) throws {
        let pwc = try playerWindowControllerForUUID(inUUID)
        
        try pwc.playerViewController.advanceToTimeInMilliseconds(time)
    }
    
    func captureCurrentFrameForVideWithUUID(uuid inUUID: UUID, andSaveTo saveLocation: URL, referenceUUID: UUID, then callback: @escaping (Bool, NSError?, UInt?, UInt?) -> ()) throws {
        let pwc = try playerWindowControllerForUUID(inUUID)
        
        switch validateURLSchemeForURL(saveLocation) {
        case .error(let error):
            callback(false, error, nil, nil)
            return
        default:
            break
        }
        
        frameCaptureCallbacks[referenceUUID] = callback
        pwc.playerViewController.grabFrameAndSaveItTo(saveLocation, destinationUUID: referenceUUID)
    }
    

    
    func receivedFrameGrabbingOutcome(_ outcome:PlayerViewController.FrameGrabbingOutcome) {
        
        DispatchQueue.main.async {
            
            switch outcome {
            case .failure (let error, let requestedTime, let destinationUUID):
                if let callback = self.frameCaptureCallbacks.removeValue(forKey: destinationUUID as UUID) {
                    callback(false, error, requestedTime, nil)
                }
                
                
            case .success(let requestedTime, let destinationUUID, let actualTime):
                if let callback = self.frameCaptureCallbacks.removeValue(forKey: destinationUUID as UUID) {
                    callback(true, nil, requestedTime, actualTime)
                }
                break
            }
        }
    }

    // MARK:- SharkVideoCoordination:Control
    
    func focusWindowForVideoWithUUID(uuid inUUID:UUID) throws {
        let pwc = try playerWindowControllerForUUID(inUUID)
        
        pwc.window?.makeKeyAndOrderFront(self)
    }
    
    func closeWindowForVideoWithUUID(uuid inUUID:UUID) throws {
        let pwc = try playerWindowControllerForUUID(inUUID)

        pwc.close()
    }

    
    func playVideoWithUUID(uuid inUUID:UUID, rate:Double) throws {
        let pwc = try playerWindowControllerForUUID(inUUID)
        
        pwc.playerViewController.playVideoAtRate(rate)
    }
    
    ////    Pauses the playback for the video specified by the UUID
    func pauseVideoWithUUID(uuid inUUID:UUID) throws {
        let pwc = try playerWindowControllerForUUID(inUUID)
        
        pwc.playerViewController.pauseVideo(self)
    }
    
    
    func advanceToNextFrameInVideoWithUUID(uuid inUUID:UUID, byFrameCount:Int) throws {
        let pwc = try playerWindowControllerForUUID(inUUID)

        try pwc.playerViewController.advanceByFrameNumber(1)
    }

    enum ErrorCode : Int {
        case unsupportedURL = 11
        case noVideoForThisUUID = 12
        case noURLForThisUUID = 13
        case focusedVideoWindowDoesNotExist = 14
        case bizarreInconsistency = 99
    }
}

// MARK:-

extension VideoPlayerCoordinator : PlayerWindowControllerDelegate {
    
    func playerWindowWillClose(_ notification: Notification) {
        let window = notification.object as! NSWindow
        let playerWC = window.windowController as! PlayerWindowController
        
        // don't manage the player anymore
        // also, release it so that playback will end...
        videoPlayerWindowControllers.removeValue(forKey: playerWC.uuid! as UUID)
    }
    
    func playerWindowDidAppear(_ notification: Notification) {
        let window = notification.object as! NSWindow
        let playerWC = window.windowController as! PlayerWindowController

        frontmostPlayerWindowController = playerWC
    }
    
    func playerWindowDidBecomeMain(_ notification: Notification) {
        let window = notification.object as! NSWindow
        let playerWC = window.windowController as! PlayerWindowController
        
        frontmostPlayerWindowController = playerWC
    }
}
