//
//  DeviceMananger.swift
//  AVFoundationMultiCameraWithSwiftUI
//
//  Created by 온석태 on 10/18/24.
//

import Foundation
import AVFoundation

class DeviceMananger {
    var cameraManager: CameraManager?
    var audioMananger: AudioMananger?
    
    var cameraViewMode:CameraViewMode = .singleScreen
    
    init() {
        if AVCaptureMultiCamSession.isMultiCamSupported {
            self.cameraViewMode = .doubleScreen
        }
        
        self.cameraManager = CameraManager(cameraViewMode: self.cameraViewMode)
        self.cameraManager?.setAppendQueueCallback(appendQueueCallback: self)
        self.audioMananger = AudioMananger()
    }
    
    
    deinit {
        print("DeviceMananger deinit")
    }
    
    public func unreference() {
        self.cameraManager?.unreference()
        self.audioMananger?.unreference()
        
        self.cameraManager = nil
        self.audioMananger = nil
    }
}

extension DeviceMananger:AppendQueueProtocol {
    func appendVideoQueue(pixelBuffer: CVPixelBuffer, time: CMTime, position: AVCaptureDevice.Position) {
        
    }
    
    func appendAudioQueue(sampleBuffer: CMSampleBuffer) {
        
    }
}
