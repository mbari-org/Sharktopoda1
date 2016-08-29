//
//  VideoFrameGrabber.swift
//  SharktopodaTest
//
//  Created by Joseph Wardell on 8/27/16.
//  Copyright © 2016 Joseph Wardell. All rights reserved.
//

import Cocoa
import AVFoundation

class VideoFrameGrabber: NSObject {

    let asset : AVAsset
    
    private let imageGenerator : AVAssetImageGenerator
    
    init(asset:AVAsset) {
        self.asset = asset
        imageGenerator = AVAssetImageGenerator(asset: asset)
    }
    
    var successCallback : (requestedTime:CMTime, actualTime:CMTime, destinationURL:NSURL, destinationUUID:NSUUID)->() = { _, _, _, _ in }
    var failureCallback : (requestedTime:CMTime, error:NSError) -> () = { _ in }
    
    private var frameInfo = [CMTimeValue:(NSURL, NSUUID)]()
    
    func grabImageAtTime(time:CMTime, savingToLocation saveLocation:NSURL, associatedWithUUID uuid:NSUUID) {
        
        frameInfo[time.value] = (saveLocation, uuid)
        
        let times = [NSValue(CMTime:time)]
        imageGenerator.requestedTimeToleranceBefore = asset.minSeekTolerance ?? kCMTimeZero
        imageGenerator.requestedTimeToleranceAfter = asset.minSeekTolerance ?? kCMTimeZero
        
        imageGenerator.generateCGImagesAsynchronouslyForTimes(times, completionHandler: completion)
    }
    
    private func completion(requestedTime:CMTime, image:CGImage?, actualTime:CMTime, result:AVAssetImageGeneratorResult, error:NSError?) {
        
        switch result {
        case .Failed:
            failureCallback(requestedTime:requestedTime, error: error!)
        case .Succeeded:
            gotImage(image!, atTime: actualTime, requestedTime: requestedTime)
        case .Cancelled:
            let error = NSError(domain: "VideoFrameGrabber", code: 1, userInfo: [NSLocalizedDescriptionKey:"Frame Grabbing was cancelled before this frame could be grabbed (time:\(requestedTime)"])
            failureCallback(requestedTime: requestedTime, error: error)
        }
    }
    
    private lazy var savingQueue : NSOperationQueue = {
        $0.maxConcurrentOperationCount = 1  // make it a serial queue
        return $0
    }(NSOperationQueue())

    private func gotImage(image:CGImage, atTime actualTime:CMTime, requestedTime:CMTime) {
        print("\(#function) \(actualTime.milliseconds) (requested:\(requestedTime.milliseconds))")
        
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
                let error = NSError(domain: "VideoFrameGrabber", code: 2, userInfo:
                    [NSLocalizedDescriptionKey: "Unable to create destination for saving image to \(saveLocation)"])
                self.failureCallback(requestedTime: requestedTime, error: error)
                return
            }
            
            // go for lossless compression to save on time
            let properties = [String(kCGImageDestinationLossyCompressionQuality):1] as NSDictionary
            CGImageDestinationAddImage(destination, image, properties)
            
            guard CGImageDestinationFinalize(destination) else {
                let error = NSError(domain: "VideoFrameGrabber", code: 3, userInfo:
                    [NSLocalizedDescriptionKey: "Unable to write image to \(saveLocation)"])
                self.failureCallback(requestedTime: requestedTime, error: error)
                return
            }
            // note: no need for CFRelease, swift handles memory management, YAY!!!
 
            self.successCallback(requestedTime: requestedTime, actualTime: actualTime, destinationURL: saveLocation, destinationUUID: uuid)
        }
    }
}
