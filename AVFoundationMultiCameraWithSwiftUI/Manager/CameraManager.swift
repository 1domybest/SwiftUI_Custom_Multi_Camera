//
//  CameraManager.swift
//  HypyG
//
//  Created by 온석태 on 11/25/23.
//

import AVFoundation
import UIKit
import SwiftUI

///
/// 카메라 매니저
///
/// - Parameters:
/// - Returns:
///
class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public var singleCameraView: CameraMetalView? // 단일 카메라뷰
    
    public var multiCameraView: MultiCameraView? // 멀티 카메라뷰
    
    // 공통
    var cameraViewMode: CameraViewMode = .doubleScreen
    
    private var delgate: CameraOutputCallback? // 프레임 콜백
    private var appendQueueCallback: AppendQueueProtocol? // 렌더링후 실행하는 콜백
    
    private var previousImageBuffer: CVPixelBuffer? // 이전 프레임 이미지 버퍼
    private var previousTimeStamp: CMTime? // 이전 프레임 시간
    
    public var isMultiCamSupported: Bool = false // 다중 카메라 지원 유무
    private var isUltraWideCamera: Bool = true // 울트라 와이드 == 후면카메라 3개인지 0.5줌 가능유무
    
    // 카메라
    private var backCamera: AVCaptureDevice? // 후면카메라 [공통]
    private var frontCamera: AVCaptureDevice? // 전면 카메라 [공통]
    
    // 멀티세션 디바이스 세션 변수
    private var dualVideoSession:AVCaptureSession? // 멀티 카메라 세션
    
    private var multiCameraCaptureInput: AVCaptureDeviceInput? // 멀티 카메라 캡처 인풋
    
    
    private var multiBackCameraConnection: AVCaptureConnection? // 멀티 후면 카메라 커넥션
    private var multiFrontCameraConnection: AVCaptureConnection? // 멀티 전면 카메라 커넥션
    
    private var multiBackCameraCaptureInput: AVCaptureDeviceInput? // 멀티 후면 카메라 인풋
    private var multiFrontCameraCaptureInput: AVCaptureDeviceInput? // 멀티 전면 카메라 인풋
    
    private var multiBackCameravideoOutput: AVCaptureVideoDataOutput? // 후면 카메라 아웃풋
    private var multiFrontCameravideoOutput: AVCaptureVideoDataOutput? // 전면 카메라 아웃풋
    
    
    // 단일 디바이스 세션 변수
    private var backCaptureSession: AVCaptureSession? // 후면 카메라 세션
    private var frontCaptureSession: AVCaptureSession? // 전면 카메라 세션
    
    private var backCameraConnection: AVCaptureConnection? // 후면 카메라 커넥션
    private var frontCameraConnection: AVCaptureConnection? // 전면 카메라 커넥션
    
    private var backCameraCaptureInput: AVCaptureDeviceInput? // 후면 카메라 인풋
    private var frontCameraCaptureInput: AVCaptureDeviceInput? // 전면 카메라 인풋
    
    private var backCameravideoOutput: AVCaptureVideoDataOutput? // 후면 카메라 아웃풋
    private var frontCameravideoOutput: AVCaptureVideoDataOutput? // 전면 카메라 아웃풋
    
    // 멀티 디바이스 상태 변수
    public var mainCameraPostion: AVCaptureDevice.Position = .back // 카메라 포지션
    
    // 더블 스크린 관련변수
    private var mirrorBackCamera = false // 미러모드 유무
    private var mirrorFrontCamera = true // 미러모드 유무
    
    // 단일 디바이스 상태 변수
    public var position: AVCaptureDevice.Position = .back // 카메라 포지션
    
    public var preset: AVCaptureSession.Preset = .hd1280x720 // 화면 비율
    public var videoOrientation: AVCaptureVideoOrientation = .portrait // 카메라 가로 세로 모드
    private var mirrorCamera = true // 미러모드 유무
    
    // 큐
    private var sessionQueue: DispatchQueue? // 세션 큐
    private var videoDataOutputQueue: DispatchQueue? // 아웃풋 큐
    
    // 권한
    private var hasCameraPermission = false // 카메라 권한 유무
    
    
    // 줌관련 변수
    var backCameraCurrentZoomFactor: CGFloat = 1.0
    var backCameraDefaultZoomFactor: CGFloat = 1.0
    var backCameraMinimumZoonFactor: CGFloat = 1.0
    var backCameraMaximumZoonFactor: CGFloat = 1.0
    
    var frontCameraCurrentZoomFactor: CGFloat = 1.0
    var frontCameraDefaultZoomFactor: CGFloat = 1.0
    var frontCameraMinimumZoonFactor: CGFloat = 1.0
    var frontCameraMaximumZoonFactor: CGFloat = 1.0
    
    
    var frameRate:Double = 30.0 // 초당 프레임
    
    private var thumbnail: CVPixelBuffer? // 썸네일
    
    var displayLink: CADisplayLink? // 카메라 종료시 반복문으로 돌릴 링크
    
    init(cameraViewMode: CameraViewMode) {
        self.cameraViewMode = cameraViewMode
        super.init()
        
        
        let attr = DispatchQueue.Attributes()
        sessionQueue = DispatchQueue(label: "camera.single.sessionqueue", attributes: attr)
        videoDataOutputQueue = DispatchQueue(label: "camera.single.videoDataOutputQueue")

        self.isMultiCamSupported = AVCaptureMultiCamSession.isMultiCamSupported
        
        self.singleCameraView = CameraMetalView()
        
        if self.isMultiCamSupported {
            self.multiCameraView = MultiCameraView(parent: self)
            self.setupMultiCaptureSessions()
        } else {
            self.setupCaptureSessions()
        }
        
        self.setupGestureRecognizers()
    }
    
    ///
    /// 카메라 deit 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    deinit {
        print("CamerManager deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
    public func unreference() {
        self.multiCameraView?.unreference()
        self.multiCameraView = nil
        self.singleCameraView = nil
        self.sessionQueue = nil
        self.videoDataOutputQueue = nil
        self.delgate = nil
        self.appendQueueCallback = nil
    }
    
    func setupGestureRecognizers() {
        // 단일 카메라 뷰에 핀치 제스처 추가
        let singleCameraPinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(singleViewHandlePinchGesture(_:)))
        singleCameraView?.addGestureRecognizer(singleCameraPinchGesture)
    }
    
    
    func setupPanGesture() {
        // 서브 카메라 뷰에 드래그 제스처 추가
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(smallViewHandlePanGesture(_:)))
        panGesture.delegate = self
        multiCameraView?.isUserInteractionEnabled = true
        multiCameraView?.addGestureRecognizer(panGesture)
    }
    
    @objc func smallViewHandlePanGesture(_ gesture: UIPanGestureRecognizer) {
        
        guard let view = gesture.view else { return }
        
        // 제스처 상태에 따라 위치 업데이트
        let translation = gesture.translation(in: view.superview)
        
        switch gesture.state {
        case .began, .changed:
            // 뷰의 새로운 위치 계산
            let newCenter = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
            print("새로운 위치 \(newCenter.x) - \(newCenter.y)")
            view.center = newCenter
            // 제스처의 변화를 리셋
            gesture.setTranslation(.zero, in: view.superview)
        case .ended, .cancelled:
            // 드래그가 끝났을 때 추가 처리 (예: 진동 효과, 애니메이션 등)
            print("드래그 종료")
        default:
            break
        }
    }
    
    @objc func singleViewHandlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        if self.isMultiCamSupported && self.position == .front { return }
        if gesture.state == .changed {

            let scale = Double(gesture.scale)
            
            var preZoomFactor: Double = .zero
            var zoomFactor: Double = .zero
            
            // 전면 또는 후면 카메라에 따라 줌 값 계산
            if position == .front {
                preZoomFactor = frontCameraCurrentZoomFactor * scale
                zoomFactor = min(max(preZoomFactor, self.frontCameraMinimumZoonFactor), self.frontCameraMaximumZoonFactor)
            } else {
                preZoomFactor = backCameraCurrentZoomFactor * scale
                zoomFactor = min(max(preZoomFactor, self.backCameraMinimumZoonFactor), self.backCameraMaximumZoonFactor)
            }
            
            // 줌 값 적용
            self.setZoom(position: position, zoomFactor: zoomFactor)
            
            // 스케일 값 초기화
            gesture.scale = 1.0
        }
    }
    
    ///
    /// 카메라 init 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func setupCaptureSessions() {
        self.backCamera = self.findDevice(withPosition: .back)
        self.frontCamera = self.findDevice(withPosition: .front)
        
        guard let backCamera = backCamera else { return }
        guard let frontCamera = frontCamera else { return }
        
        DispatchQueue.main.async {
            // Setup back camera session
            self.backCaptureSession = AVCaptureSession()
            
            if let backCaptureSession = self.backCaptureSession {
                backCaptureSession.beginConfiguration()
                backCaptureSession.sessionPreset = self.preset
                backCaptureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
                
                self.setupInput(for: backCaptureSession, position: .back)
                // Set desired frame rate
                self.setFrameRate(desiredFrameRate: self.frameRate, for: backCamera)
                
                self.setupOutput(for: backCaptureSession, position: .back)
                
                
                backCaptureSession.commitConfiguration()
            }
            
            self.frontCaptureSession = AVCaptureSession()
            
            if let frontCaptureSession = self.frontCaptureSession {
                frontCaptureSession.beginConfiguration()
                frontCaptureSession.sessionPreset = self.preset
                frontCaptureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
                
                self.setupInput(for: frontCaptureSession, position: .front)
                
                // Set desired frame rate
                self.setFrameRate(desiredFrameRate: self.frameRate, for: frontCamera)
                
                self.setupOutput(for: frontCaptureSession, position: .front)
                
                frontCaptureSession.commitConfiguration()
            }
            
            self.sessionQueue?.async {
                if self.position == .back {
                    self.backCaptureSession?.startRunning()
                } else {
                    self.frontCaptureSession?.startRunning()
                }
            }
        }
       
    }
    
    func setupMultiCaptureSessions() {
        self.backCamera = self.findDeviceForMultiSession(withPosition: .back)
        self.frontCamera = self.findDeviceForMultiSession(withPosition: .front)
        
        DispatchQueue.main.async {
            self.dualVideoSession = AVCaptureMultiCamSession()
            if let dualVideoSession = self.dualVideoSession {
                dualVideoSession.beginConfiguration()
                
                self.setupInput(for: dualVideoSession, position: .front, isMultiSession: true)
                self.setupInput(for: dualVideoSession, position: .back, isMultiSession: true)
                
                self.setupOutput(for: dualVideoSession, position: .front, isMultiSession: true)
                self.setupOutput(for: dualVideoSession, position: .back, isMultiSession: true)
                
                dualVideoSession.commitConfiguration()
            }
            
            
            self.sessionQueue?.async {
                self.dualVideoSession?.startRunning()
            }
        }
       
    }
    
    ///
    /// 카메라 프레임레이트 [fps] 지정함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func setFrameRate(desiredFrameRate: Double, for camera: AVCaptureDevice) {
        var bestFormat: AVCaptureDevice.Format?
        var bestFrameRateRange: AVFrameRateRange?
        
        for format in camera.formats {
              for range in format.videoSupportedFrameRateRanges {
                  // Check if the format supports desired resolution and frame rate
                  let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                  if dimensions.width == Int32(1280) && dimensions.height == Int32(720) &&
                     range.maxFrameRate >= desiredFrameRate && range.minFrameRate <= desiredFrameRate {
                      if bestFormat == nil || range.minFrameRate < bestFrameRateRange?.minFrameRate ?? Double.greatestFiniteMagnitude {
                          bestFormat = format
                          bestFrameRateRange = range
                      }
                  }
              }
          }
        
        if let selectedFormat = bestFormat, let selectedFrameRateRange = bestFrameRateRange {
            do {
                try camera.lockForConfiguration()
                
                // 포맷 설정
                camera.activeFormat = selectedFormat
                
                // 프레임 레이트 설정
                camera.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFrameRate))
                camera.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFrameRate))
                
                camera.unlockForConfiguration()
                
                print("Successfully set frame rate to \(desiredFrameRate) fps for \(camera.position.rawValue) camera.")
            } catch {
                print("Failed to set frame rate for \(camera.position.rawValue) camera: \(error.localizedDescription)")
            }
        } else {
            print("Desired frame rate \(desiredFrameRate) fps is not supported for \(camera.position.rawValue) camera.")
        }
    }
    
    ///
    /// 카메라 input 설정함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func setupInput(for session: AVCaptureSession, position: AVCaptureDevice.Position, isMultiSession: Bool = false) {
        guard let device = position == .back ? self.backCamera : self.frontCamera else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        do {
            if isMultiSession {
                if position == .back {
                    self.multiBackCameraCaptureInput = input
                } else {
                    self.multiFrontCameraCaptureInput = input
                }
                dualVideoSession?.addInputWithNoConnections(input)
            } else {
                if position == .back {
                    self.backCameraCaptureInput = input
                    backCaptureSession?.canAddInput(input)
                    backCaptureSession?.addInput(input)
                } else {
                    self.frontCameraCaptureInput = input
                    frontCaptureSession?.canAddInput(input)
                    frontCaptureSession?.addInput(input)
                }
            }
        } catch {
            print("에러")
        }
    }
    
    ///
    /// 카메라 output 설정함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func setupOutput(for session: AVCaptureSession, position: AVCaptureDevice.Position, isMultiSession: Bool = false) {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if isMultiSession {
            if position == .front {
                guard let frontVideoPort = self.multiFrontCameraCaptureInput?.ports(for: .video, sourceDeviceType: frontCamera?.deviceType, sourceDevicePosition: .front).first else {
                    print("Unable to get front video port.")
                    return
                }
                
                if dualVideoSession?.canAddOutput(videoOutput) ?? false {
                    dualVideoSession?.addOutputWithNoConnections(videoOutput)
                }
                
                let frontOutputConnection = AVCaptureConnection(inputPorts: [frontVideoPort], output: videoOutput)
                
                guard dualVideoSession?.canAddConnection(frontOutputConnection) ?? false else {
                    print("no connection to the front camera video data output")
                    return
                }
                
                dualVideoSession?.addConnection(frontOutputConnection)
                frontOutputConnection.videoOrientation = .portrait
                frontOutputConnection.isVideoMirrored = true
                self.multiFrontCameraConnection = frontOutputConnection
                
            } else {
                
                guard let backVideoPort = self.multiBackCameraCaptureInput?.ports(for: .video, sourceDeviceType: backCamera?.deviceType, sourceDevicePosition: .back).first else { return }
                
                if dualVideoSession?.canAddOutput(videoOutput) ?? false {
                    dualVideoSession?.addOutputWithNoConnections(videoOutput)
                }
                
                let backOutputConnection = AVCaptureConnection(inputPorts: [backVideoPort], output: videoOutput)
                
                guard dualVideoSession?.canAddConnection(backOutputConnection) ?? false else {
                    print("no connection to the back camera video data output")
                    return
                }
                
                dualVideoSession?.addConnection(backOutputConnection)
                backOutputConnection.videoOrientation = .portrait
                backOutputConnection.isVideoMirrored = false
                self.multiBackCameraConnection = backOutputConnection
            }
        } else {
            if session.canAddOutput(videoOutput) {
                if isMultiSession {
                    
                    session.addOutputWithNoConnections(videoOutput)
                } else {
                    session.addOutput(videoOutput)
                }
                
            } else {
                fatalError("Could not add video output")
            }
            
            videoOutput.connections.first?.videoOrientation = videoOrientation
            
            if position == .front {
                self.frontCameravideoOutput = videoOutput
                self.frontCameraConnection = videoOutput.connection(with: .video)
                self.frontCameraConnection?.isVideoMirrored = true
            } else {
                self.backCameravideoOutput = videoOutput
                self.backCameraConnection = videoOutput.connection(with: .video)
                self.backCameraConnection?.isVideoMirrored = false
            }
        }
    }
    
//    ///
//    /// output 용 콜백등록
//    ///
//    /// - Parameters:
//    /// - Returns:
//    ///
//    func setAppendQueueCallback (appendQueueCallback: AppendQueueProtocol) {
//    }
    
    ///
    /// 카메라 퍼미션 체크 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func checkCameraPermission() {
        let mediaType = AVMediaType.video
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            hasCameraPermission = true
            
        case .notDetermined:
            sessionQueue?.suspend()
            AVCaptureDevice.requestAccess(for: mediaType) { [weak self] granted in
                guard let self = self else { return }
                self.hasCameraPermission = granted
                self.sessionQueue?.resume()
            }
            
        case .denied:
            hasCameraPermission = false
            
        default:
            break
        }
    }
    
    ///
    /// 사용하고있는 기기의 방향에 따른 기기정보 가져오는 함수
    ///
    /// - Parameters:
    ///     - position ( AVCaptureDevice ) : 카메라 방향
    /// - Returns: AVCaptureDevice?
    ///
    func findDevice(withPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        var deviceTypes = [AVCaptureDevice.DeviceType]()
        
        if #available(iOS 13.0, *) {
            deviceTypes.append(contentsOf: [.builtInDualWideCamera])
            deviceTypes.append(contentsOf: [.builtInTripleCamera])
            self.isUltraWideCamera = true
        }
        
        if deviceTypes.isEmpty {
            isUltraWideCamera = false
        }
        
        deviceTypes.append(contentsOf: [.builtInWideAngleCamera])
        
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        ).devices
        
        for device in devices {
            if let tripleCamera = devices.first(where: { $0.deviceType == .builtInTripleCamera }) {
                // 트리플 카메라를 가장 높은 우선순위로 선택
                if position == .back {
                    backCameraMinimumZoonFactor = tripleCamera.minAvailableVideoZoomFactor
                    backCameraMaximumZoonFactor = tripleCamera.maxAvailableVideoZoomFactor
                    backCameraDefaultZoomFactor = 2.0
                    backCameraCurrentZoomFactor = backCameraDefaultZoomFactor
                    
                    print("트리플 카메라 - 후면 - 최소줌 \(backCameraMinimumZoonFactor) 최대줌\(backCameraMaximumZoonFactor) 기본줌 \(backCameraDefaultZoomFactor)")
                } else {
                    frontCameraMinimumZoonFactor = tripleCamera.minAvailableVideoZoomFactor
                    frontCameraMaximumZoonFactor = tripleCamera.maxAvailableVideoZoomFactor
                    frontCameraDefaultZoomFactor = 1.0
                    frontCameraCurrentZoomFactor = frontCameraDefaultZoomFactor
                    print("트리플 카메라 - 전면 - 최소줌 \(frontCameraMinimumZoonFactor) 최대줌\(frontCameraMaximumZoonFactor) 기본줌 \(frontCameraDefaultZoomFactor)")
                }
                return tripleCamera
            } else if let dualWideCamera = devices.first(where: { $0.deviceType == .builtInDualWideCamera }) {
                if position == .back {
                    // 트리플 카메라가 없으면 듀얼 와이드 카메라 선택
                    backCameraMinimumZoonFactor = dualWideCamera.minAvailableVideoZoomFactor
                    backCameraMaximumZoonFactor = dualWideCamera.maxAvailableVideoZoomFactor
                    backCameraDefaultZoomFactor = 2.0
                    backCameraCurrentZoomFactor = backCameraDefaultZoomFactor
                    
                    print("듀얼 카메라 - 후면 - 최소줌 \(backCameraMinimumZoonFactor) 최대줌\(backCameraMaximumZoonFactor) 기본줌 \(backCameraDefaultZoomFactor)")
                } else {
                    frontCameraMinimumZoonFactor = dualWideCamera.minAvailableVideoZoomFactor
                    frontCameraMaximumZoonFactor = dualWideCamera.maxAvailableVideoZoomFactor
                    frontCameraDefaultZoomFactor = 1.0
                    frontCameraCurrentZoomFactor = frontCameraDefaultZoomFactor
                    print("듀얼 카메라 - 전면 - 최소줌 \(frontCameraMinimumZoonFactor) 최대줌\(frontCameraMaximumZoonFactor) 기본줌 \(frontCameraDefaultZoomFactor)")
                }
                return dualWideCamera
            } else if let normalCamera = devices.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
                if position == .back {
                    // 트리플 카메라가 없으면 듀얼 와이드 카메라 선택
                    backCameraMinimumZoonFactor = normalCamera.minAvailableVideoZoomFactor
                    backCameraMaximumZoonFactor = normalCamera.maxAvailableVideoZoomFactor
                    backCameraDefaultZoomFactor = 1.0
                    backCameraCurrentZoomFactor = backCameraDefaultZoomFactor
                    
                    print("노멀 카메라 - 후면 - 최소줌 \(backCameraMinimumZoonFactor) 최대줌\(backCameraMaximumZoonFactor) 기본줌 \(backCameraDefaultZoomFactor)")
                } else {
                    frontCameraMinimumZoonFactor = normalCamera.minAvailableVideoZoomFactor
                    frontCameraMaximumZoonFactor = normalCamera.maxAvailableVideoZoomFactor
                    frontCameraDefaultZoomFactor = 1.0
                    frontCameraCurrentZoomFactor = frontCameraDefaultZoomFactor
                    
                    print("노멀 카메라 - 전면 - 최소줌 \(frontCameraMinimumZoonFactor) 최대줌\(frontCameraMaximumZoonFactor) 기본줌 \(frontCameraDefaultZoomFactor)")
                }
                return normalCamera
            }
            
            
        }
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
  
    
    ///
    /// 멀티세션에서 사용할 디바이스의 카메라 가져오기
    ///
    /// - Parameters:
    ///     - position ( AVCaptureDevice ) : 카메라 방향
    /// - Returns: AVCaptureDevice?
    ///
    func findDeviceForMultiSession(withPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        var deviceTypes = [AVCaptureDevice.DeviceType]()
        
        if #available(iOS 13.0, *) {
            deviceTypes.append(contentsOf: [.builtInDualWideCamera])
            deviceTypes.append(contentsOf: [.builtInTripleCamera])
            self.isUltraWideCamera = true
        }
        
        if deviceTypes.isEmpty {
            isUltraWideCamera = false
        }
        
        deviceTypes.append(contentsOf: [.builtInWideAngleCamera])
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        )
        
        // 지원되는 멀티 카메라 세트 확인
        let supportedDeviceSets = discoverySession.supportedMultiCamDeviceSets
        
        for device in supportedDeviceSets {
            // 지원되는 멀티 카메라 세트 내에서 장치 선택
            if let tripleCamera = device.first(where: { $0.deviceType == .builtInTripleCamera && $0.position == position }) {
                if position == .back {
                    backCameraMinimumZoonFactor = tripleCamera.minAvailableVideoZoomFactor
                    backCameraMaximumZoonFactor = tripleCamera.maxAvailableVideoZoomFactor
                    backCameraDefaultZoomFactor = 2.0
                    backCameraCurrentZoomFactor = backCameraDefaultZoomFactor
                    
                    print("트리플 카메라 - 후면 - 최소줌 \(backCameraMinimumZoonFactor) 최대줌\(backCameraMaximumZoonFactor) 기본줌 \(backCameraDefaultZoomFactor)")
                } else {
                    frontCameraMinimumZoonFactor = tripleCamera.minAvailableVideoZoomFactor
                    frontCameraMaximumZoonFactor = tripleCamera.maxAvailableVideoZoomFactor
                    frontCameraDefaultZoomFactor = 1.0
                    frontCameraCurrentZoomFactor = frontCameraDefaultZoomFactor
                    print("트리플 카메라 - 전면 - 최소줌 \(frontCameraMinimumZoonFactor) 최대줌\(frontCameraMaximumZoonFactor) 기본줌 \(frontCameraDefaultZoomFactor)")
                }
                return tripleCamera
            } else if let dualWideCamera = device.first(where: { $0.deviceType == .builtInDualWideCamera && $0.position == position }) {
                if position == .back {
                    // 트리플 카메라가 없으면 듀얼 와이드 카메라 선택
                    backCameraMinimumZoonFactor = dualWideCamera.minAvailableVideoZoomFactor
                    backCameraMaximumZoonFactor = dualWideCamera.maxAvailableVideoZoomFactor
                    backCameraDefaultZoomFactor = 2.0
                    backCameraCurrentZoomFactor = backCameraDefaultZoomFactor
                    
                    print("듀얼 카메라 - 후면 - 최소줌 \(backCameraMinimumZoonFactor) 최대줌\(backCameraMaximumZoonFactor) 기본줌 \(backCameraDefaultZoomFactor)")
                } else {
                    frontCameraMinimumZoonFactor = dualWideCamera.minAvailableVideoZoomFactor
                    frontCameraMaximumZoonFactor = dualWideCamera.maxAvailableVideoZoomFactor
                    frontCameraDefaultZoomFactor = 1.0
                    frontCameraCurrentZoomFactor = frontCameraDefaultZoomFactor
                    print("듀얼 카메라 - 전면 - 최소줌 \(frontCameraMinimumZoonFactor) 최대줌\(frontCameraMaximumZoonFactor) 기본줌 \(frontCameraDefaultZoomFactor)")
                }
                return dualWideCamera
            } else if let normalCamera = device.first(where: { $0.deviceType == .builtInWideAngleCamera && $0.position == position }) {
                if position == .back {
                    // 트리플 카메라가 없으면 듀얼 와이드 카메라 선택
                    backCameraMinimumZoonFactor = normalCamera.minAvailableVideoZoomFactor
                    backCameraMaximumZoonFactor = normalCamera.maxAvailableVideoZoomFactor
                    backCameraDefaultZoomFactor = 1.0
                    backCameraCurrentZoomFactor = backCameraDefaultZoomFactor
                    
                    print("노멀 카메라 - 후면 - 최소줌 \(backCameraMinimumZoonFactor) 최대줌\(backCameraMaximumZoonFactor) 기본줌 \(backCameraDefaultZoomFactor)")
                } else {
                    frontCameraMinimumZoonFactor = normalCamera.minAvailableVideoZoomFactor
                    frontCameraMaximumZoonFactor = normalCamera.maxAvailableVideoZoomFactor
                    frontCameraDefaultZoomFactor = 1.0
                    frontCameraCurrentZoomFactor = frontCameraDefaultZoomFactor
                    
                    print("노멀 카메라 - 전면 - 최소줌 \(frontCameraMinimumZoonFactor) 최대줌\(frontCameraMaximumZoonFactor) 기본줌 \(frontCameraDefaultZoomFactor)")
                }
                return normalCamera
            }
        }
        
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
    
    ///
    /// 전/후 면 카메라 지정함수 [단일 스크린일경우만]
    ///
    /// - Parameters:
    ///     - position ( AVCaptureDevice ) : 카메라 방향
    /// - Returns:
    ///
    func setPosition(_ position: AVCaptureDevice.Position) {
        DispatchQueue.main.async {
            self.position = position
            
            if self.isMultiCamSupported {
                self.setMirrorMode(isMirrorMode: position == .front)
            } else {
                if position == .back {
                    self.frontCaptureSession?.stopRunning()
                    self.backCaptureSession?.startRunning()
                    self.setZoom(position: .back, zoomFactor: self.backCameraDefaultZoomFactor)
                    self.setMirrorMode(isMirrorMode: false)
                } else {
                    self.backCaptureSession?.stopRunning()
                    self.frontCaptureSession?.startRunning()
                    self.setZoom(position: .front, zoomFactor: self.frontCameraCurrentZoomFactor)
                    self.setMirrorMode(isMirrorMode: true)
                }
            }
           
        }
    }
    
    
    func switchMainCamera (mainCameraPostion: AVCaptureDevice.Position) {
        self.mainCameraPostion = mainCameraPostion
    }
    
    ///
    /// 카메라 좌우반전 설정
    ///
    /// - Parameters:
    ///    - isMirrorMode ( Bool ) : 기본: 전면카메라 = true / 후면카메라 = false
    /// - Returns:
    ///
    func setMirrorMode (isMirrorMode: Bool) {
        
        if self.isMultiCamSupported {
            if self.cameraViewMode == .singleScreen {
                
                self.mirrorCamera = isMirrorMode
                
                if self.position == .back {
                    self.multiBackCameraConnection?.isVideoMirrored = self.mirrorCamera
                } else {
                    self.multiFrontCameraConnection?.isVideoMirrored = self.mirrorCamera
                }
            } else {
                if self.position == .back {
                    self.mirrorBackCamera = isMirrorMode
                    self.multiBackCameraConnection?.isVideoMirrored = self.mirrorBackCamera
                } else {
                    self.mirrorFrontCamera = isMirrorMode
                    self.multiFrontCameraConnection?.isVideoMirrored = self.mirrorFrontCamera
                }
            }
        } else {
            
            self.mirrorCamera = isMirrorMode
            
            if self.position == .back {
                self.backCameraConnection?.isVideoMirrored = mirrorCamera
            } else {
                self.frontCameraConnection?.isVideoMirrored = mirrorCamera
            }
        }
        
    }
    
    ///
    /// 가로/세로 모드에 따른 비디오 방향설정 함수
    ///
    /// - Parameters:
    ///     - videoOrientation ( AVCaptureVideoOrientation ) : 기기방향
    /// - Returns:
    ///
    func setVideoOrientation(_ videoOrientation: AVCaptureVideoOrientation) {
        self.videoOrientation = videoOrientation
        backCameraConnection?.videoOrientation = videoOrientation
    }
    
    ///
    /// 캡처세션의 해상도를 설정하는 함수
    ///
    /// - Parameters:
    ///    - preset ( AVCaptureSession.Preset ) : 해상도
    /// - Returns:
    ///
    func setPreset(_ preset: AVCaptureSession.Preset) {
        guard let captureSession = backCaptureSession else { return }
        
        if captureSession.isRunning && self.preset != preset {
            self.preset = preset
            sessionQueue?.async { [weak self] in
                self?.switchPreset()
            }
        } else {
            self.preset = preset
        }
    }
    
    ///
    /// 캡처세션의 해상도변경 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func switchPreset() {
        guard let captureSession = backCaptureSession else { return }
        
        captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(preset) {
            captureSession.sessionPreset = preset
        } else {
            if captureSession.canSetSessionPreset(.vga640x480) {
                captureSession.sessionPreset = .vga640x480
                print("Preset not supported, using default")
            } else {
                print("Unable to set session preset")
                captureSession.commitConfiguration()
                return
            }
        }
        captureSession.commitConfiguration()
    }

    ///
    /// 화면 줌했을시 카메라의 Zoom 을 해주는 함수
    ///
    /// - Parameters:
    ///    - scale ( CGFloat ) : 줌 정도
    /// - Returns:
    ///
    @objc
    func handlePinchCamera(_ scale: CGFloat) {
        let currentPostion = self.isMultiCamSupported ? self.mainCameraPostion : self.position
        
        var preZoomFactor:Double = .zero
        var zoomFactor:Double = .zero
        
        if self.position == .front {
            preZoomFactor = frontCameraCurrentZoomFactor * scale
            zoomFactor = min(max(preZoomFactor, self.frontCameraMinimumZoonFactor), self.frontCameraMaximumZoonFactor)
        } else {
            preZoomFactor = backCameraCurrentZoomFactor * scale
            zoomFactor = min(max(preZoomFactor, self.backCameraMinimumZoonFactor), self.backCameraMaximumZoonFactor)
        }
        
        self.setZoom(position: currentPostion, zoomFactor: zoomFactor)
    }
    
    func setZoom(position: AVCaptureDevice.Position, zoomFactor: CGFloat) {
        if let device = position == .front ? self.frontCamera : self.backCamera {

            if position == .front {
                self.frontCameraCurrentZoomFactor = zoomFactor
            } else {
                self.backCameraCurrentZoomFactor = zoomFactor
            }
            
            do {
                try device.lockForConfiguration()
                print("적용된 스케일\(zoomFactor)")
                device.videoZoomFactor = zoomFactor
            } catch {
                return
            }
            
            device.unlockForConfiguration()
        }
    }
    
    ///
    /// 카메라 기기 시작함수 단 퍼미션확인후 상수에 등록
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func startCamera() {
        checkCameraPermission()
        sessionQueue?.async { [weak self] in
            self?.startCameraInternal()
        }
    }

    
    ///
    /// 카메라 세션 시작함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func startCameraInternal() {
        if displayLink != nil {
            displayLink?.invalidate() // DisplayLink를 중지
            displayLink = nil
        }
        
        if self.position == .front {
            self.frontCaptureSession?.startRunning()
        } else {
            self.backCaptureSession?.startRunning()
        }
    }
    
    ///
    /// 카메라 세션 정지함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func stopCamera() {
//        sessionQueue?.async { [weak self] in
//            self?.stopCameraInternal()
//        }
    }
    
    ///
    /// 카메라 세션 정지함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func stopCameraInternal(isPause: Bool = false) {
        if self.position == .front {
            self.frontCaptureSession?.stopRunning()
        } else {
            self.backCaptureSession?.stopRunning()
        }
        
        if isPause {
            startDisplayLink()
        }
    }
    
    func startDisplayLink() {
         displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
         // iOS 10 이상에서는 preferredFramesPerSecond를 사용하여 프레임 속도 조절
         displayLink?.preferredFramesPerSecond = Int(self.frameRate) // 초당 30프레임
        
         displayLink?.add(to: .main, forMode: .common)
     }
    
    
    @objc func handleDisplayLink(_ displayLink: CADisplayLink) {
        // 여기에서 프레임 처리 로직을 실행
        if let captureSession = self.backCaptureSession, !captureSession.isRunning {
        }
    }
    
    
    
    
    ///
    /// 카메라 포커스 변경함수
    ///
    /// - Parameters:
    ///    - pointOfInterest ( CGPoint ) : 누른 화면좌표
    /// - Returns: Bool
    ///
    func changeDeviceFocusPointOfInterest(to pointOfInterest: CGPoint) -> Bool {
        guard pointOfInterest.x <= 1, pointOfInterest.y <= 1, pointOfInterest.x >= 0,
              pointOfInterest.y >= 0
        else {
            return false
        }
        
        if let captureDevice = backCamera, captureDevice.isFocusModeSupported(.continuousAutoFocus),
           captureDevice.isFocusPointOfInterestSupported
        {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.focusPointOfInterest = pointOfInterest
                captureDevice.focusMode = .continuousAutoFocus
                captureDevice.unlockForConfiguration()
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    ///
    /// 카메라 노출조절 함수
    ///
    /// - Parameters:
    ///    - pointOfInterest ( CGPoint ) : 노출정도
    /// - Returns: Bool
    ///
    func changeDeviceExposurePointOfInterest(to pointOfInterest: CGPoint) -> Bool {
        guard pointOfInterest.x <= 1, pointOfInterest.y <= 1, pointOfInterest.x >= 0, pointOfInterest.y >= 0,
              let captureDevice = backCamera,
              captureDevice.isExposureModeSupported(.continuousAutoExposure),
              captureDevice.isExposurePointOfInterestSupported
        else {
            return false
        }
        
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.exposurePointOfInterest = pointOfInterest
            captureDevice.exposureMode = .continuousAutoExposure
            captureDevice.unlockForConfiguration()
            return true
        } catch {
            return false
        }
    }
    
//    func createThumbnailImage () {
//        // SwiftUI 뷰의 인스턴스 생성
//        let swiftUIView = LiveStreamingThumbnailImage()
//
//        // SwiftUI 뷰를 UIHostingController에 래핑
//        let hostingController = UIHostingController(rootView: swiftUIView)
//
//        // 뷰 크기 조정
//        hostingController.view.frame = CGRect(x: 0, y: 0, width: ScreenSize.shader.screenWidthSize, height: (ScreenSize.shader.screenWidthSize / 9) * 16)
//
//        // 뷰가 업데이트되었는지 확인
//        hostingController.view.backgroundColor = .clear
//
//        // UIImage 생성
//        if let uiImage = createImage(from: hostingController.view) {
//            // 여기에서 uiImage를 사용할 수 있습니다.
//
//            // CIImage로 변환할 경우
//            if let ciImage = CIImage(image: uiImage) {
//                self.thumbnail = toPixelBuffer(image: ciImage)
//            }
//        }
//    }
    
    // 이미지로 변환하는 함수
    func createImage(from view: UIView) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        return renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }
    
    
    private func toPixelBuffer(image: CIImage) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        
        // kCVPixelFormatType_32BGRA 로 변경
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(image.extent.width),
            Int(image.extent.height),
            kCVPixelFormatType_32BGRA, // 여기를 BGRA로 변경
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let pixelBuffer = pixelBuffer else {
            return nil
        }
        
        // CVPixelBuffer에 CIImage의 내용을 쓰기
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let ciContext = CIContext()
        ciContext.render(image, to: pixelBuffer, bounds: image.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        return pixelBuffer
    }
    
    func setCameraViewMode (cameraViewMode: CameraViewMode) {
        
        if cameraViewMode == .singleScreen {
            self.setPosition(self.mainCameraPostion)
        } else {
            self.mainCameraPostion = self.position
        }
        self.cameraViewMode = cameraViewMode
    }
    

    ///
    /// 카메라 세션 실행시 매프레임마다 callback 되는 함수
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
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
              return
          }
          // 타임스탬프 추출
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        self.previousImageBuffer = pixelBuffer
        self.previousTimeStamp = timestamp
        
        guard let sourcePostion: AVCaptureDevice.Position = connection.inputPorts.first?.sourceDevicePosition else { return }
        
        if self.cameraViewMode == .singleScreen {
            self.singleCameraModeRender(sourceDevicePosition: sourcePostion, sampleBuffer: sampleBuffer)
        } else if self.cameraViewMode == .doubleScreen {
            self.doubleScreenCameraModeRender(sourceDevicePosition: sourcePostion, sampleBuffer: sampleBuffer)
        } else {
            
        }
        
    }
    
    func doubleScreenCameraModeRender (sourceDevicePosition: AVCaptureDevice.Position, sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
              return
          }
          // 타임스탬프 추출
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        self.previousImageBuffer = pixelBuffer
        self.previousTimeStamp = timestamp
        
        switch sourceDevicePosition {
        case .front:
            if self.mainCameraPostion == .front {
                self.multiCameraView?.updateMainCameraBuffer(buffer: sampleBuffer)
                delgate?.backCameraFrameOutput?(pixelBuffer: pixelBuffer, time: timestamp)
            } else {
                self.multiCameraView?.updateSmallCameraBuffer(buffer: sampleBuffer)
                delgate?.backCameraFrameOutput?(pixelBuffer: pixelBuffer, time: timestamp)
            }
        case .back:
            if self.mainCameraPostion == .back {
                self.multiCameraView?.updateMainCameraBuffer(buffer: sampleBuffer)
                delgate?.backCameraFrameOutput?(pixelBuffer: pixelBuffer, time: timestamp)
            } else {
                self.multiCameraView?.updateSmallCameraBuffer(buffer: sampleBuffer)
                delgate?.frontCameraFrameOutput?(pixelBuffer: pixelBuffer, time: timestamp)
            }
        default:
            break
        }
    }
    
    func singleCameraModeRender (sourceDevicePosition: AVCaptureDevice.Position, sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
              return
          }
          // 타임스탬프 추출
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        self.previousImageBuffer = pixelBuffer
        self.previousTimeStamp = timestamp
        
        switch sourceDevicePosition {
        case .front:
            if self.position == .front {
                self.singleCameraView?.update(buffer: sampleBuffer)
                delgate?.frontCameraFrameOutput?(pixelBuffer: pixelBuffer, time: timestamp)
            }
        case .back:
            if self.position == .back {
                self.singleCameraView?.update(buffer: sampleBuffer)
                delgate?.backCameraFrameOutput?(pixelBuffer: pixelBuffer, time: timestamp)
            }
        default:
            self.singleCameraView?.update(buffer: sampleBuffer)
            delgate?.unknownCameraFrameOutput?(pixelBuffer: pixelBuffer, time: timestamp)
            print("기타 장치의 프레임입니다.")
        }
    }
    
    ///
    /// 기기 플레쉬 장치 on/off 함수
    ///
    /// - Parameters:
    ///    - onTorch ( Bool ) : 장치 켜짐 유무
    /// - Returns:
    ///
    func toggleTorch(onTorch: Bool) {
        guard let device = backCamera, device.hasTorch else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = onTorch ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Error toggling torch: \(error)")
        }
    }
    
    ///
    /// 기기 플레쉬 장치 on/off 함수
    ///
    /// - Parameters:
    ///    - onTorch ( Bool ) : 장치 켜짐 유무
    /// - Returns:
    ///
    func doseHaseTorch() -> Bool {
        guard let device = backCamera, device.hasTorch else {
            return false
        }
        return true
    }
}


extension CameraManager: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


class MultiCameraView: UIView, UIGestureRecognizerDelegate {
    // 부모 참조하기
    var parent: CameraManager?
    
    public var smallCameraView: CameraMetalView? // 서브 카메라뷰
    public var mainCameraView: CameraMetalView? // 서브 카메라뷰

    init(parent: CameraManager) {
        super.init(frame: .zero)
        self.parent = parent
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    deinit {
        print("MultiCameraView deinit")
    }
    
    public func unreference() {
        self.parent = nil
    }

    private func setupView() {
        // 전체 화면을 차지하도록 설정
        self.backgroundColor = .clear // 필요에 따라 배경색 설정
        
        mainCameraView = CameraMetalView()
        
        mainCameraView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: ((UIScreen.main.bounds.width) / 9)  * 16 )
        
        if let mainCameraView = mainCameraView {
            self.addSubview(mainCameraView)
        }
        
        // 메인 카메라 뷰에 핀치 제스처 추가
        let mainCameraPinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(multiViewHandlePinchGesture(_:)))
        mainCameraView?.addGestureRecognizer(mainCameraPinchGesture)
        

        // 작은 카메라 뷰 설정
        smallCameraView = CameraMetalView() // 원하는 크기로 설정
        smallCameraView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width/4, height: ((UIScreen.main.bounds.width / 4) / 9)  * 16 )

        if let smallCameraView = smallCameraView {
            self.addSubview(smallCameraView)
        }

        // 드래그 제스처 추가
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        smallCameraView?.addGestureRecognizer(panGesture)
        
        // 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.delegate = self // delegate 설정 (필요한 경우)
        smallCameraView?.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        print("smallCameraView 탭됨")
        // 탭 제스처 처리 로직을 여기에 추가
        guard let parent = self.parent else { return }
        let postion:AVCaptureDevice.Position = parent.mainCameraPostion == .front ? .back : .front
        parent.switchMainCamera(mainCameraPostion: postion)
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let view = self.smallCameraView else { return }
        
        let translation = gesture.translation(in: self)
        
        switch gesture.state {
        case .began, .changed:
            let newCenter = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
            
            // 뷰가 부모 뷰의 경계를 넘어가지 않도록 제한
            let halfWidth = view.bounds.width / 2
            let halfHeight = view.bounds.height / 2
            
            let minX = halfWidth
            let maxX = self.bounds.width - halfWidth
            let minY = halfHeight
            let maxY = self.bounds.height - halfHeight
            
            view.center = CGPoint(
                x: min(max(newCenter.x, minX), maxX),
                y: min(max(newCenter.y, minY), maxY)
            )
            
            // 제스처의 변화를 리셋
            gesture.setTranslation(.zero, in: self)
            
        case .ended, .cancelled:
            print("드래그 종료")
        default:
            break
        }
    }
    
    @objc func multiViewHandlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let parent = self.parent else { return }
        guard let view = gesture.view else { return }
        if parent.mainCameraPostion == .front { return }
        print("줌 제스처")
        if gesture.state == .changed {
            let scale = Double(gesture.scale)

            var preZoomFactor: Double = .zero
            var zoomFactor: Double = .zero
            
            // 전면 또는 후면 카메라에 따라 줌 값 계산
            if parent.mainCameraPostion == .front {
                preZoomFactor = parent.frontCameraCurrentZoomFactor * scale
                zoomFactor = min(max(preZoomFactor, parent.frontCameraMinimumZoonFactor), parent.frontCameraMaximumZoonFactor)
            } else {
                preZoomFactor = parent.backCameraCurrentZoomFactor * scale
                zoomFactor = min(max(preZoomFactor, parent.backCameraMinimumZoonFactor), parent.backCameraMaximumZoonFactor)
            }
            
            // 줌 값 적용
            parent.setZoom(position: parent.mainCameraPostion, zoomFactor: zoomFactor)
            
            // 스케일 값 초기화
            gesture.scale = 1.0
        }
    }
    
    
    public func updateSmallCameraBuffer(buffer: CMSampleBuffer) {
        self.smallCameraView?.update(buffer: buffer)
    }
    
    public func updateMainCameraBuffer(buffer: CMSampleBuffer) {
        self.mainCameraView?.update(buffer: buffer)
    }
    
    // Gesture Recognizer Delegate Method
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 두 제스처 인식기가 동시에 인식될 수 있도록 허용
        return true
    }
}
