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
    var singleRecordManager: RecordManager?
    var doubleRecordManager: RecordManager?
    
    var cameraViewMode:CameraViewMode = .singleScreen
    var cameraSessionMode:CameraSessionMode = .multiSession
    
    var isRecording: Bool = false
    
    init(cameraViewMode:CameraViewMode, cameraSessionMode:CameraSessionMode) {
        self.cameraViewMode = cameraViewMode
        self.cameraSessionMode = cameraSessionMode
//        if AVCaptureMultiCamSession.isMultiCamSupported {
//            self.cameraViewMode = .doubleScreen
//        }
        
        self.setMananger()
    }
    
    deinit {
        print("DeviceMananger deinit")
    }
    
    func setMananger () {
        self.cameraManager = CameraManager(cameraSessionMode: self.cameraSessionMode, cameraViewMode: self.cameraViewMode)
        
        self.cameraManager?.setAppendQueueCallback(appendQueueCallback: self)
        self.audioMananger = AudioMananger()
        self.audioMananger?.setAppendQueueCallback(appendQueueCallback: self)
        self.singleRecordManager = RecordManager()
        self.singleRecordManager?.setRecordManangerProtocol(recordManangerProtocol: self)
        self.doubleRecordManager = RecordManager()
        self.doubleRecordManager?.setRecordManangerProtocol(recordManangerProtocol: self)
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
        if self.cameraViewMode == .singleScreen {
            singleRecordManager?.appendVideoQueue(pixelBuffer: pixelBuffer, time: time, position: position)
        } else {
            if position == .front {
                singleRecordManager?.appendVideoQueue(pixelBuffer: pixelBuffer, time: time, position: position)
            } else {
                doubleRecordManager?.appendVideoQueue(pixelBuffer: pixelBuffer, time: time, position: position)
            }
        }
    }
    
    func appendAudioQueue(sampleBuffer: CMSampleBuffer) {
        if self.cameraViewMode == .singleScreen {
            singleRecordManager?.appendAudioQueue(sampleBuffer: sampleBuffer)
        } else {
            singleRecordManager?.appendAudioQueue(sampleBuffer: sampleBuffer)
            doubleRecordManager?.appendAudioQueue(sampleBuffer: sampleBuffer)
        }
    }
}

extension DeviceMananger:RecordManangerProtocol {
    func onFinishedRecord(fileURL: URL, position: AVCaptureDevice.Position) {
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    func statusDidChange(captureStatus: CaptureStatus) {
    }
    
    func onStartRecord() {
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }
}


// SingleSession
extension DeviceMananger {
    func setSingleSessionCameraPostion (postion: AVCaptureDevice.Position) {
        self.cameraManager?.setPosition(postion)
    }

}

// MultiSession
extension DeviceMananger {
    func setMultiSessionCameraPostion (postion: AVCaptureDevice.Position) {
        if self.isRecording { return }
        self.cameraManager?.switchMainCamera(mainCameraPostion: postion)
    }

    func setMultiSessionScreenMode(cameraViewMode: CameraViewMode) {
        if self.isRecording { return }
        self.cameraViewMode = cameraViewMode
        self.cameraManager?.setCameraViewMode(cameraViewMode: cameraViewMode)
    }
}
