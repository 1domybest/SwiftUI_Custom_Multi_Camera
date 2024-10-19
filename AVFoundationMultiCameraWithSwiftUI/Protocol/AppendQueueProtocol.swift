//
//  AppendQueueProtocol.swift
//  HypyG
//
//  Created by 온석태 on 11/25/23.
//

import AVFoundation
import Foundation

///
/// AppendQueueProtocol 프로토콜
///
/// - Parameters:
/// - Returns:
///
protocol AppendQueueProtocol {
    ///
    /// 비디오관련 버퍼 생성시 매프레임마다 callback
    ///
    /// - Parameters:
    ///    - pixelBuffer ( CVPixelBuffer ) : 카메라에서 받아온 프레임 버퍼
    ///    - time ( CMTime ) : SampleBuffer에 등록된 타임스탬프
    /// - Returns:
    ///
    func appendVideoQueue(pixelBuffer: CVPixelBuffer, time: CMTime, position: AVCaptureDevice.Position)
    
    ///
    /// 오디오 관련 버퍼 생성시 매프레임마다 callback (촬영에는 사용되지만 스트리밍에서는 사용안함)
    ///
    /// - Parameters:
    ///    - sampleBuffer ( CMSampleBuffer ) : 마이크에서 받아온 프레임 버퍼
    /// - Returns:
    ///
    func appendAudioQueue(sampleBuffer: CMSampleBuffer)
}
