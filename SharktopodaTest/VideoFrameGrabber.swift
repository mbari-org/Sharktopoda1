//
//  VideoFrameGrabber.swift
//  Sharktopoda
//
//  Created by Joseph Wardell on 8/27/16.
//

import Cocoa
import AVFoundation

class VideoFrameGrabber: NSObject {

    
    struct Errors {
        static let Cancelled = 1
        static let FailedToCreateDestination = 2
        static let FailedToWrite = 3
    }

    
    let asset : AVAsset
    
    private let imageGenerator : AVAssetImageGenerator
    
    init(asset:AVAsset) {
        self.asset = asset
        imageGenerator = AVAssetImageGenerator(asset: asset)
    }
    
    var successCallback : (requestedTime:CMTime, actualTime:CMTime, destinationURL:NSURL, destinationUUID:NSUUID)->() = { _, _, _, _ in }
    var failureCallback : (requestedTime:CMTime, error:NSError, destinationUUID:NSUUID) -> () = { _ in }
    
    private var frameInfo = [CMTimeValue:(NSURL, NSUUID)]()
    
    func grabImageAtTime(time:CMTime, savingToLocation saveLocation:NSURL, associatedWithUUID uuid:NSUUID) {
        
        frameInfo[time.value] = (saveLocation, uuid)
        
        let times = [NSValue(CMTime:time)]
        // always take the previous fram to the time passed in (or the frame exactly at the time passed in...)
        imageGenerator.requestedTimeToleranceBefore = asset.frameDuration ?? kCMTimeZero
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero
        
        imageGenerator.generateCGImagesAsynchronouslyForTimes(times, completionHandler: completion)
    }
    
    private func completion(requestedTime:CMTime, image:CGImage?, actualTime:CMTime, result:AVAssetImageGeneratorResult, error:NSError?) {
        
        var responseError = error
        
        switch result {
        case .Succeeded:
            gotImage(image!, atTime: actualTime, requestedTime: requestedTime)
        case .Cancelled:
            responseError = NSError(domain: "VideoFrameGrabber", code: Errors.Cancelled, userInfo: [NSLocalizedDescriptionKey:"Frame Grabbing was cancelled before this frame could be grabbed (time:\(requestedTime)"])
            fallthrough
        case .Failed:
            let (_, uuid) = frameInfo.removeValueForKey(requestedTime.value)!
            failureCallback(requestedTime:requestedTime, error: responseError!, destinationUUID:uuid)
        }
    }
    
    private lazy var savingQueue : NSOperationQueue = {
        $0.maxConcurrentOperationCount = 1  // make it a serial queue
        return $0
    }(NSOperationQueue())

    private func gotImage(image:CGImage, atTime actualTime:CMTime, requestedTime:CMTime) {
        
        let (saveLocation, uuid) = frameInfo.removeValueForKey(requestedTime.value)!
        
        savingQueue.addOperationWithBlock() {
            
            var type : NSString = kUTTypeJPEG   // default assumption
            if let ext = saveLocation.pathExtension {
                switch ext {
                case "png":
                    type = kUTTypePNG
                case "bmp":
                    type = kUTTypeBMP
                case "tiff", "tif":
                    type = kUTTypeTIFF
                default:
                    break
                }
            }
            
            guard let destination = CGImageDestinationCreateWithURL(saveLocation, type, 1, nil) else {
                let error = NSError(domain: "VideoFrameGrabber", code:Errors.FailedToCreateDestination, userInfo:
                    [NSLocalizedDescriptionKey: "Unable to create destination for saving image to \(saveLocation)"])
                self.failureCallback(requestedTime: requestedTime, error: error, destinationUUID:uuid)
                return
            }
            
            // go for lossless compression to save on time
            let properties = [String(kCGImageDestinationLossyCompressionQuality):1] as NSDictionary
            
            // save the file
            CGImageDestinationAddImage(destination, image, properties)
            guard CGImageDestinationFinalize(destination) else {
                let error = NSError(domain: "VideoFrameGrabber", code: Errors.FailedToWrite, userInfo:
                    [NSLocalizedDescriptionKey: "Unable to write image to \(saveLocation)"])
                self.failureCallback(requestedTime: requestedTime, error: error, destinationUUID:uuid)
                return
            }
            // note: no need for CFRelease, swift handles memory management, YAY!!!
 
            self.successCallback(requestedTime: requestedTime, actualTime: actualTime, destinationURL: saveLocation, destinationUUID: uuid)
        }
    }
}
