//
//  RecordManangerDelegate.swift
//  AVFoundationMultiCameraWithSwiftUI
//
//  Created by 온석태 on 10/19/24.
//

import Foundation
import AVFoundation

protocol RecordManangerProtocol {
    func statusDidChange(captureStatus: CaptureStatus)
    func onStartRecord()
    func onFinishedRecord(fileURL: URL, position: AVCaptureDevice.Position)
}
