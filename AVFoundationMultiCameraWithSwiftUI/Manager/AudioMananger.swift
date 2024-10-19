//
//  AudioMananger.swift
//  HypyG
//
//  Created by 온석태 on 11/25/23.
//

import AVFoundation

///
/// 오디오 매니저
///
/// - Parameters:
/// - Returns:
///
class AudioMananger: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    public var captureSession: AVCaptureSession?
    
    private var audioCaptureDevice: AVCaptureDevice?
    private var audioCaptureInput: AVCaptureDeviceInput?
    
    private var audioOutput: AVCaptureAudioDataOutput?
    
    private var audioConnection: AVCaptureConnection?
    
    private var sessionQueue: DispatchQueue?
    private var audioCaptureQueue: DispatchQueue?
    
    private var hasMicrophonePermission = false
    
    private var recommendedAudioSettings: [AnyHashable: Any]?
    
    private var appendQueueCallback: AppendQueueProtocol?
    
    override init() {
        super.init()
        setup()
    }
    
    ///
    /// 오디오 init 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    private func setup() {
        hasMicrophonePermission = false
        
        captureSession = AVCaptureSession()
        
        let attr = DispatchQueue.Attributes()
        sessionQueue = DispatchQueue(label: "ai.deepar.sessionqueue", attributes: attr)
        
        audioCaptureQueue = DispatchQueue(label: "com.deepar.audio", attributes: attr)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startAudio),
            name: Notification.Name("deepar_start_audio"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopAudio),
            name: Notification.Name("deepar_stop_audio"),
            object: nil
        )
        
        self.startAudio()
    }
    
    ///
    /// 카메라 deinit 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    deinit {
        print("AudioManager deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
    public func unreference() {
        appendQueueCallback = nil
    }
    
    ///
    /// 오디오 퍼미션 체크 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func checkMicrophonePermission() {
        let mediaType = AVMediaType.audio
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            hasMicrophonePermission = true
            
        case .notDetermined:
            sessionQueue?.suspend()
            AVCaptureDevice.requestAccess(for: mediaType) { [weak self] granted in
                guard let self = self else { return }
                self.hasMicrophonePermission = granted
                self.sessionQueue?.resume()
            }
            
        case .denied:
            hasMicrophonePermission = false
            
        default:
            break
        }
    }
    
    
    ///
    /// 오디오 세션 정지 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    @objc
    func stopAudio() {
        sessionQueue?.async { [weak self] in
            self?.stopAudioInternal()
        }
    }
    
    
    ///
    /// 오디오 세션 정지 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func stopAudioInternal() {
        print("stopAudioInternal")
        if let captureSession = self.captureSession {
            if captureSession.isRunning {
                captureSession.removeInput(audioCaptureInput!)
                audioCaptureInput = nil
                captureSession.removeOutput(audioOutput!)
                audioOutput = nil
                audioConnection = nil
                captureSession.stopRunning()
            }
        }
    }
    
    
    ///
    /// 오디오 세션 시작함수  단 퍼미션확인후 상수에 등록
    ///
    /// - Parameters:
    /// - Returns:
    ///
    @objc
    func startAudio() {
        checkMicrophonePermission()
        sessionQueue?.async { [weak self] in
            self?.startAudioInternal()
        }
    }
    
    ///
    /// output 에서 받은 데이터를 넘겨줄 callback함수를 등록하는 함수
    ///
    /// - Parameters:
    ///    - appendQueueCallback ( AppendQueueProtocol ) : 프로토콜로 등록한 클래스를 넘겨줌
    /// - Returns:
    ///
    func setAppendQueueCallback(appendQueueCallback: AppendQueueProtocol) {
        self.appendQueueCallback = appendQueueCallback
    }
    
    ///
    /// 오디오 세션 시작
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func startAudioInternal() {
        guard hasMicrophonePermission else {
            return
        }
        
        captureSession?.beginConfiguration()
        
        if let audioCaptureDevice = AVCaptureDevice.default(for: .audio) {
            audioCaptureInput = try? AVCaptureDeviceInput(device: audioCaptureDevice)
            if let audioCaptureInput = audioCaptureInput,
               captureSession?.canAddInput(audioCaptureInput) == true
            {
                captureSession?.addInput(audioCaptureInput)
            } else {
                print("Unable to add audio input")
                captureSession?.commitConfiguration()
                return
            }
        }
        
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: audioCaptureQueue)
        if captureSession?.canAddOutput(audioOutput) == true {
            captureSession?.addOutput(audioOutput)
            self.audioOutput = audioOutput
        } else {
            print("Unable to add audio output")
            captureSession?.commitConfiguration()
            return
        }
        
        audioConnection = audioOutput.connection(with: .audio)
        
        captureSession?.commitConfiguration()
        captureSession?.startRunning()
        
    }
    
    ///
    /// 오디오 세션 실행시 매프레임마다 callback 되는 함수
    ///
    /// - Parameters:
    ///    - _ ( AVCaptureOutput ) : 아웃풋에대한 정보
    ///    - sampleBuffer ( AVCaptureConnection ) : 카메라에서 받아온 샘플정보
    ///    - from ( AVCaptureConnection ) :기기정보[카메라 혹은 마이크]
    /// - Returns:
    ///
    func captureOutput(
        _: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from _: AVCaptureConnection
    ) {
        appendQueueCallback?.appendAudioQueue(sampleBuffer: sampleBuffer)
    }
}

