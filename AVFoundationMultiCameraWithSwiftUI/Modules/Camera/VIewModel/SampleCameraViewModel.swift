//
//  SampleCameraViewModel.swift
//  HypyG
//
//  Created by 온석태 on 10/2/24.
//

import Foundation
import AVFoundation


class SampleCameraViewModel: ObservableObject {
    var deviceMananger: DeviceMananger?
    @Published var isSingleScreenMode: Bool = false
    @Published var isRecording: Bool = false
    
    var isFrontCamera: Bool = false
    var isFrontMainCamera: Bool = false

    @Published var cameraViewMode:CameraViewMode = .singleScreen
    @Published var cameraSessionMode:CameraSessionMode = .multiSession
    var isMultiCamSupported:Bool = false
    init() {
        self.isMultiCamSupported = AVCaptureMultiCamSession.isMultiCamSupported
        
        if !self.isMultiCamSupported {
            self.cameraSessionMode = .singleSession
            self.cameraViewMode = .singleScreen
        }
        
        self.deviceMananger = DeviceMananger(cameraViewMode: self.cameraViewMode, cameraSessionMode: self.cameraSessionMode)
        
        self.deviceMananger?.singleRecordManager?.setRecordManangerProtocol(recordManangerProtocol: self)
        self.deviceMananger?.doubleRecordManager?.setRecordManangerProtocol(recordManangerProtocol: self)
    }
    
    deinit {
        print("SampleCameraViewModel deinit")
    }
    
    public func unreference() {
        self.deviceMananger?.unreference()
        self.deviceMananger = nil
    }
}

// SingleSession
extension SampleCameraViewModel {
    func toggleSingleSessionCameraPostion () {
        self.isFrontCamera = self.deviceMananger?.cameraManager?.position == .front
        self.isFrontCamera.toggle()
        self.deviceMananger?.setSingleSessionCameraPostion(postion: self.isFrontCamera ? .front : .back)
    }
}

// MultiSession
extension SampleCameraViewModel {
    
    func toggleMultiSessionCameraPostion () {
        if self.isRecording { return }
        if self.cameraSessionMode == .multiSession {
            self.isFrontMainCamera = self.deviceMananger?.cameraManager?.mainCameraPostion == .front
            self.isFrontMainCamera.toggle()
            self.deviceMananger?.setMultiSessionCameraPostion(postion: self.isFrontMainCamera ? .front : .back)
        }
    }
    
    func switchMultiSessionScreenMode() {
        if self.isRecording { return }
        if self.cameraSessionMode == .multiSession {
            self.cameraViewMode = self.cameraViewMode == .singleScreen ? .doubleScreen : .singleScreen
            self.deviceMananger?.setMultiSessionScreenMode(cameraViewMode: self.cameraViewMode)
        }
    }
}


extension SampleCameraViewModel:RecordManangerProtocol {
    
    func statusDidChange(captureStatus: CaptureStatus) {
    }
    
    func onStartRecord() {
        if !isRecording {
            DispatchQueue.main.async {
                self.isRecording = true
            }
        }
    }
    
    func onFinishedRecord(fileURL: URL, position: AVCaptureDevice.Position) {
        if isRecording {
            DispatchQueue.main.async {
                self.isRecording = false
            }
        }
    }
}
