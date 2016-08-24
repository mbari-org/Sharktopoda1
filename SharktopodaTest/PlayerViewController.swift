//
//  PlayerViewController.swift
//  AVPlayerTest
//
//  Created by Joseph Wardell on 8/22/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//
// with many thanks to charlesboyd https://gist.github.com/charlesboyd/e0e840e8af9e52836d51

import Cocoa
import AVKit
import AVFoundation
import MediaAccessibility

final class PlayerViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
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
            view.window?.title = url?.lastPathComponent ?? "Movie"
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
    

    override func viewWillAppear() {
        super.viewWillAppear()
        
        if nil == videoPlayer {
            // TODO: see if we can keep the window hidden until the status has changed to something we know will work...
            // could be a better experience than blitting the window...
            openVideo()
        }
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
            updateWindowForMediaSize()
        }
    }

    
    // MARK:- Video Setup
    
    var videoLoadCompletionCallback : ((success:Bool, error:NSError?) -> ())?
    
    private func openVideo() {
        
        guard let url = url else { return }
        
        videoPlayer = AVPlayer(URL: url)
        playerView.player = videoPlayer
        
        videoPlayer?.allowsExternalPlayback = false

        // hide the player and start the spinner
        playerView.hidden = true
        spinner?.startAnimation(self)
        
        videoPlayer?.currentItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil);
        videoPlayer?.currentItem?.addObserver(self, forKeyPath: "presentationSize", options: NSKeyValueObservingOptions(), context: nil);

        // TODO: there should be a reasonable timeout
    }
    
    func processVideoPlayerStatus() {
        
        //Verify we can read info about the asset currently loading
        if(videoPlayer?.currentItem == nil || videoPlayer?.currentItem?.status == nil){
            // this is too rare and wild to report to the suer, we just want the video windo to disappear in this case
            let desc = ("A video asset's status changed but the asset or its status returned nil. Status unknown.");
            print(desc)
            videoLoadFailed(withError: NSError(domain: "PlayerViewController", code: 1, userInfo: [NSLocalizedDescriptionKey:desc]))
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
            print(desc)
                        
            videoLoadFailed(withError: paybackError ?? NSError(domain: "PlayerViewController", code: 2, userInfo: [NSLocalizedDescriptionKey:desc]));
        }else if(videoStatus == AVPlayerItemStatus.Unknown){
            //The asset should have started in an Unknown state, so it *should* not have changed into this state
            let desc = ("A video asset has an unknown status. (Asset Description: \(assetString))");
            print(desc)
            // this is another case that's too weird to show the user
            videoLoadFailed((withError: NSError(domain: "PlayerViewController", code: 3, userInfo: [NSLocalizedDescriptionKey:desc])));
        }
        
        //De-register for infomation about the item because it is now either ready or failed to load
        videoPlayer?.currentItem?.removeObserver(self, forKeyPath: "status");
    }
    

    func videoReady(){

        spinner?.stopAnimation(self)
        playerView.hidden = false
        
        // apparently, this must be set here, after the video is ready, or it will turn on anyway
        videoPlayer?.allowsExternalPlayback = false
        
        // notify the callback that loading was successful
        videoLoadCompletionCallback?(success:true, error:nil)
        videoLoadCompletionCallback = nil   // clear it to be safe
    }
    
    func videoLoadFailed(withError error:NSError){
        
        // There's no video to show, so close the window
        // if it's appropriate, the calling method has handled user notification
        view.window?.windowController?.close()
        
        print("The video load failed! (See the console output)");
        
        // notify the callback that loading failed and pass along the error
        videoLoadCompletionCallback?(success: false, error: error)
        videoLoadCompletionCallback = nil   // clear it to be safe
    }

    var videoPlaybackRate : Double {
        return Double(videoPlayer?.rate ?? 0)
    }
    
    // MARK:- Actions
    
    @IBAction func playVideo(sender:AnyObject) {
        
        playVideoAtRate()
    }
    
    @IBAction func pauseVideo(sender:AnyObject) {
        
        videoPlayer?.pause()
    }

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


    
    // MARK:- UI Updating
    
    func updateWindowForMediaSize() {
        
        view.window?.setContentSize(playerView.player!.currentItem!.presentationSize)
        view.window?.center()
        
        videoPlayer?.currentItem?.removeObserver(self, forKeyPath: "presentationSize");
    }

}
