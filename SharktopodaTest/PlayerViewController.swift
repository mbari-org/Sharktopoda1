//
//  PlayerViewController.swift
//  AVPlayerTest
//
//  Created by Joseph Wardell on 8/22/16.
//
// with many thanks to charlesboyd https://gist.github.com/charlesboyd/e0e840e8af9e52836d51

import Cocoa
import AVKit
import AVFoundation
import CoreMedia
import MediaAccessibility

final class PlayerViewController: NSViewController {
    
    struct Errors {
        static let UnknownStatus = 1
        static let FailedToLoad = 2
        static let TimedOut = 3
        static let UnknownFrameRate = 4
    }

    
    var readyToShowVideo : () -> () = {}
    var mediaSizeChanged : (newSize:CGSize) -> () = { _ in }
    var failedToLoad : () -> () = {}
    
    var videoURL : NSURL? {
        get {
            return representedObject as? NSURL
        }
        set {
            representedObject = newValue
        }
    }
    
    override var representedObject: AnyObject? {
        didSet {
            self.title = url?.lastPathComponent ?? "Movie"
        }
    }

    @IBOutlet weak var playerView: AVPlayerView! {
        didSet {
            playerView.controlsStyle = .Floating
            playerView.showsSharingServiceButton = true
        }
    }
    
    @IBOutlet weak var spinner: NSProgressIndicator?
    
    var url : NSURL? {
        return representedObject as? NSURL
    }
    
    private var keysObserved = Set<String>()
    func observeKey(key:String) {
        videoPlayer?.currentItem?.addObserver(self, forKeyPath: key, options: NSKeyValueObservingOptions(), context: nil);
        keysObserved.insert(key)
    }
    func stopObserving(key:String) {
        if keysObserved.contains(key) {
            do {
                // occasionally, if the video load fails very early on, 
                // not all KVO has been set up and we can crash
                // unless we catch the exception thrown by removeObserver
                try trap {
                    self.videoPlayer?.currentItem?.removeObserver(self, forKeyPath: key)
                    self.keysObserved.remove(key)
                }
            }
            catch let error as NSError {
                debugPrint("error removing observer for keypath \(key): \(error.localizedDescription)")
            }
        }
    }
    func stopObservingAll() {
        for this in keysObserved {
            videoPlayer?.currentItem?.removeObserver(self, forKeyPath: this)
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        
        // if it hasn't been opened already, then open it now...
        openVideo()
    }
    
    override func viewWillDisappear() {

        // to be safe,
        // pause the video if it's playing
        videoPlayer?.pause()
        
        // to be safe, remove observers here, in case they weren't removed before
        stopObservingAll()
    }
    
    var videoPlayer:AVPlayer?
    
    // MARK:- KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        /*  Called upon a status change for the video asset requested in `loadVideo(..)`. Add the following
         code to your class's `observeValueForKeyPath` function if you already have one.
         */
        
        //Verify the call is for the videoPlayer's status change
        if(object===videoPlayer?.currentItem && keyPath!=="status") {
            processVideoPlayerStatus()
        }
        else if (keyPath == "presentationSize") {
            readyToShowVideo()
            mediaSizeChanged(newSize: videoPlayer!.currentItem!.presentationSize)
            stopObserving("presentationSize")
        }
    }

    
    // MARK:- Video Setup
    
    var videoLoadCompletionCallback : ((success:Bool, error:NSError?) -> ())?
    
    private var timeouttimer : NSTimer?
    struct Timeout {
        static let AllotedTimeForVideoLoad = NSTimeInterval(20)
    }

    func openVideo() {
        
        guard let url = url else { return }
        guard nil == videoPlayer else { return }
        
        videoPlayer = AVPlayer(URL: url)
        
        videoPlayer?.allowsExternalPlayback = false

        // hide the player and start the spinner
        playerView.hidden = true
        spinner?.startAnimation(self)
        
        observeKey("status")
        observeKey("presentationSize")

        timeouttimer = NSTimer.scheduledTimerWithTimeInterval(Timeout.AllotedTimeForVideoLoad, target: self, selector: #selector(videoLoadTimedOut(_:)), userInfo: nil, repeats: false)
    }
    
    func processVideoPlayerStatus() {
        
        timeouttimer?.invalidate()
        timeouttimer = nil
        
        //Verify we can read info about the asset currently loading
        if(videoPlayer?.currentItem == nil || videoPlayer?.currentItem?.status == nil){
            // this is too rare and wild to report to the suer, we just want the video windo to disappear in this case
            let desc = ("A video asset's status changed but the asset or its status returned nil. Status unknown.");
            debugPrint(desc)
            videoLoadFailed(withError: NSError(domain: "PlayerViewController", code: Errors.UnknownStatus, userInfo: [NSLocalizedDescriptionKey:desc]))
            return;
        }
        
        //Get infromation about the asset for use below
        let videoStatus:AVPlayerItemStatus = (videoPlayer?.currentItem!.status)!;
        let assetString:String = (videoPlayer?.currentItem!.asset.description)!;
        
        //Take different actions based on the asset's new status
        if(videoStatus == AVPlayerItemStatus.ReadyToPlay){
            debugPrint("A video asset is ready to play. (Asset Description: \(assetString))");
            videoReady();
        }else if(videoStatus == AVPlayerItemStatus.Failed){
            let paybackError:NSError? = videoPlayer?.currentItem?.error;
            let asset = videoPlayer?.currentItem!.asset;

            let desc = ("A video asset failed to load.\n\tAsset Description: \(assetString)\n\tAsset Readable: \(asset?.readable)\n\tAsset Playable: \(asset?.playable)\n\tAsset Has Protected Content: \(asset?.hasProtectedContent)\n\tFull error output:\n\(paybackError)");
            debugPrint(desc)
                        
            videoLoadFailed(withError: paybackError ?? NSError(domain: "PlayerViewController", code: Errors.FailedToLoad, userInfo: [NSLocalizedDescriptionKey:desc]));
        }else if(videoStatus == AVPlayerItemStatus.Unknown){
            //The asset should have started in an Unknown state, so it *should* not have changed into this state
            let desc = ("A video asset has an unknown status. (Asset Description: \(assetString))");
            debugPrint(desc)
            // this is another case that's too weird to show the user
            videoLoadFailed((withError: NSError(domain: "PlayerViewController", code: Errors.UnknownStatus, userInfo: [NSLocalizedDescriptionKey:desc])));
        }
        
        //De-register for infomation about the item because it is now either ready or failed to load
        stopObserving("status")
    }
    

    func videoReady(){

        spinner?.stopAnimation(self)
        playerView.hidden = false
        playerView.player = videoPlayer
        
        // apparently, this must be set here, after the video is ready, or it will turn on anyway
        videoPlayer?.allowsExternalPlayback = false
        
        // notify the callback that loading was successful
        videoLoadCompletionCallback?(success:true, error:nil)
        videoLoadCompletionCallback = nil   // clear it to be safe
    }
    
    func videoLoadFailed(withError error:NSError){
        
        // There's no video to show
        failedToLoad()
                
        // notify the callback that loading failed and pass along the error
        videoLoadCompletionCallback?(success: false, error: error)
        videoLoadCompletionCallback = nil   // clear it to be safe
        
        stopObservingAll()
    }

    func videoLoadTimedOut(sender:NSTimer) {
        let desc = "Video at \(videoURL!) failed to load in the time alloted"
        debugPrint(desc)
        videoLoadFailed((withError: NSError(domain: "PlayerViewController", code: Errors.TimedOut, userInfo: [NSLocalizedDescriptionKey:desc])));
    }
    
    var videoPlaybackRate : Double {
        return Double(videoPlayer?.rate ?? 0)
    }
    
    var videoElpasedTimeInMilliseconds : UInt {
        guard let videoPlayer = videoPlayer else { return 0 }
        
        return videoPlayer.currentTime().milliseconds
    }
    
    // MARK:- Actions
    
    @IBAction func playVideo(sender:AnyObject) {
        
        playVideoAtRate()
    }
    
    @IBAction func pauseVideo(sender:AnyObject) {
        
        videoPlayer?.pause()
    }

    // MARK:- External Methods

    func playVideoAtRate(rate:Double = 1) {
        
        let vPlayer = videoPlayer!  // If this is being called before there's a player, then there's something wrong...
        
        if vPlayer.currentTime() >= vPlayer.currentItem?.duration {
            let frameRate : Int32 = (vPlayer.currentItem!.currentTime().timescale)
            vPlayer.seekToTime(CMTimeMakeWithSeconds(0, frameRate))
        }
        
        if vPlayer.rate == 0 {
            vPlayer.play()
        }
        if rate != Double(vPlayer.rate) {
            vPlayer.setRate(Float(rate), time: kCMTimeInvalid, atHostTime: kCMTimeInvalid)
        }
    }

    func advanceToTimeInMilliseconds(milliseconds:UInt) throws {
        let time = CMTime.timeWithMilliseconds(milliseconds)

        // we give AVPlayer a little leeway in the interest of performance
        // we let it jump to the frame nearest to the value passed in
        let tolerance = videoPlayer?.currentItem?.asset.minSeekTolerance ?? kCMTimeZero
        
        videoPlayer!.seekToTime(time, toleranceBefore: tolerance, toleranceAfter: tolerance)
    }
    
    func advanceByFrameNumber(framesToAdvance:Int) throws {
        let time = videoElpasedTimeInMilliseconds

        guard let frameTime = videoPlayer?.currentItem?.asset.frameDuration?.milliseconds else {
            throw(NSError(domain: "PlayerViewController", code: Errors.UnknownFrameRate, userInfo: [NSLocalizedDescriptionKey:"Unable to determine frame rate for video at \(videoURL)"]))
        }
        
        let start = Int(frameTime * time/frameTime)  // to get the time of the current frame
        let newTime = start + Int(frameTime) * framesToAdvance
        try advanceToTimeInMilliseconds(UInt(newTime))
    }
    
    var frameGrabbingCallback : (outcome:FrameGrabbingOutcome) -> () = { _ in }
    
    enum FrameGrabbingOutcome {
        case success (requestedTimeInMilliseconds:UInt, destinationUUID:NSUUID, actualTimeInMilliseconds:UInt)
        case failure (error:NSError, requestedTimeInMilliseconds:UInt, destinationUUID:NSUUID)
    }
    
    lazy var frameGrabber : VideoFrameGrabber = {
        $0.successCallback = { requestedTime, actualTime, destinationURL, destinationUUID in
            let outcome = FrameGrabbingOutcome.success(requestedTimeInMilliseconds: requestedTime.milliseconds, destinationUUID: destinationUUID, actualTimeInMilliseconds: actualTime.milliseconds)
            self.frameGrabbingCallback(outcome:outcome)
        }
        $0.failureCallback = { requestedTime, error, destinationUUID in            
            let outcome = FrameGrabbingOutcome.failure(error:error, requestedTimeInMilliseconds:requestedTime.milliseconds, destinationUUID:destinationUUID)
            self.frameGrabbingCallback(outcome:outcome)
        }
        return $0
    }(VideoFrameGrabber(asset: self.videoPlayer!.currentItem!.asset))
    
    func grabFrameAndSaveItTo(destination:NSURL, destinationUUID:NSUUID) {
        
        let timeToGrab = videoPlayer!.currentTime()
        frameGrabber.grabImageAtTime(timeToGrab, savingToLocation: destination, associatedWithUUID: destinationUUID)
    }
}
