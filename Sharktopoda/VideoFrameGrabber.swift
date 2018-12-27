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
    
    fileprivate let imageGenerator : AVAssetImageGenerator
    
    init(asset:AVAsset) {
        self.asset = asset
        imageGenerator = AVAssetImageGenerator(asset: asset)
    }
    
    var successCallback : (_ requestedTime:CMTime, _ actualTime:CMTime, _ destinationURL:URL, _ destinationUUID:UUID)->() = { _, _, _, _ in }
    var failureCallback : (_ requestedTime:CMTime, _ error:NSError, _ destinationUUID:UUID) -> () = { _ in }
    
    fileprivate var frameInfo = [CMTimeValue:(URL, UUID)]()
    
    func grabImageAtTime(_ time:CMTime, savingToLocation saveLocation:URL, associatedWithUUID uuid:UUID) {
        
        frameInfo[time.value] = (saveLocation, uuid)
        
        let times = [NSValue(time:time)]
        // always take the previous fram to the time passed in (or the frame exactly at the time passed in...)
        imageGenerator.requestedTimeToleranceBefore = asset.frameDuration ?? kCMTimeZero
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: times, completionHandler: completion as! AVAssetImageGeneratorCompletionHandler)
    }
    
    fileprivate func completion(_ requestedTime:CMTime, image:CGImage?, actualTime:CMTime, result:AVAssetImageGeneratorResult, error:NSError?) {
        
        var responseError = error
        
        switch result {
        case .succeeded:
            gotImage(image!, atTime: actualTime, requestedTime: requestedTime)
        case .cancelled:
            responseError = NSError(domain: "VideoFrameGrabber", code: Errors.Cancelled, userInfo: [NSLocalizedDescriptionKey:"Frame Grabbing was cancelled before this frame could be grabbed (time:\(requestedTime)"])
            fallthrough
        case .failed:
            let (_, uuid) = frameInfo.removeValue(forKey: requestedTime.value)!
            failureCallback(requestedTime, responseError!, uuid)
        }
    }
    
    fileprivate lazy var savingQueue : OperationQueue = {
        $0.maxConcurrentOperationCount = 1  // make it a serial queue
        return $0
    }(OperationQueue())

    fileprivate func gotImage(_ image:CGImage, atTime actualTime:CMTime, requestedTime:CMTime) {
        
        let (saveLocation, uuid) = frameInfo.removeValue(forKey: requestedTime.value)!
        
        savingQueue.addOperation() {
            
            var type : NSString? = kUTTypeJPEG   // default assumption
            if let ext  = saveLocation.pathExtension {
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
            
            guard let destination = CGImageDestinationCreateWithURL(saveLocation as CFURL, type ?? <#default value#>, 1, nil) else {
                let error = NSError(domain: "VideoFrameGrabber", code:Errors.FailedToCreateDestination, userInfo:
                    [NSLocalizedDescriptionKey: "Unable to create destination for saving image to \(saveLocation)"])
                self.failureCallback(requestedTime, error, uuid)
                return
            }
            
            // go for lossless compression to save on time
            let properties = [String(kCGImageDestinationLossyCompressionQuality):1] as NSDictionary
            
            // save the file
            CGImageDestinationAddImage(destination, image, properties)
            guard CGImageDestinationFinalize(destination) else {
                let error = NSError(domain: "VideoFrameGrabber", code: Errors.FailedToWrite, userInfo:
                    [NSLocalizedDescriptionKey: "Unable to write image to \(saveLocation)"])
                self.failureCallback(requestedTime, error, uuid)
                return
            }
            // note: no need for CFRelease, swift handles memory management, YAY!!!
 
            self.successCallback(requestedTime, actualTime, saveLocation, uuid)
        }
    }
}
