//
//  CameraOutputCallback.swift
//  HypyG
//
//  Created by 온석태 on 10/2/24.
//

import Foundation
import AVFoundation

@objc protocol CameraOutputCallback {
    @objc optional func unknownCameraFrameOutput(pixelBuffer: CVPixelBuffer, time: CMTime)
    
    @objc optional func backCameraFrameOutput(pixelBuffer: CVPixelBuffer, time: CMTime)
    
    @objc optional func frontCameraFrameOutput(pixelBuffer: CVPixelBuffer, time: CMTime)
    
    @objc optional func audioOutput(sampleBuffer: CMSampleBuffer)
}
