//
//  MultiCameraView.swift
//  AVFoundationMultiCameraWithSwiftUI
//
//  Created by 온석태 on 10/19/24.
//

import Foundation
import UIKit
import AVFoundation

class MultiCameraView: UIView, UIGestureRecognizerDelegate {
    // 부모 참조하기
    var parent: CameraManager?

    public var smallCameraView: CameraMetalView? // 서브 카메라뷰
    public var mainCameraView: CameraMetalView? // 서브 카메라뷰
    var appendQueueCallback:AppendQueueProtocol?
    init(parent: CameraManager, appendQueueCallback: AppendQueueProtocol) {
        super.init(frame: .zero)
        self.parent = parent
        self.appendQueueCallback = appendQueueCallback
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
        self.appendQueueCallback = nil
        self.mainCameraView?.unreference()
        self.smallCameraView?.unreference()
        
        self.mainCameraView = nil
        self.smallCameraView = nil
    
    }

    private func setupView() {
        // 전체 화면을 차지하도록 설정
        self.backgroundColor = .clear // 필요에 따라 배경색 설정
        
        mainCameraView = CameraMetalView(appendQueueCallback: self)
        mainCameraView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: ((UIScreen.main.bounds.width) / 9)  * 16 )
        
        if let mainCameraView = mainCameraView {
            self.addSubview(mainCameraView)
        }
        
        // 메인 카메라 뷰에 핀치 제스처 추가
        let mainCameraPinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(multiViewHandlePinchGesture(_:)))
        mainCameraView?.addGestureRecognizer(mainCameraPinchGesture)
        

        // 작은 카메라 뷰 설정
        smallCameraView = CameraMetalView(appendQueueCallback: self) // 원하는 크기로 설정
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
    
    func setAppendQueueCallback(appendQueueCallback: AppendQueueProtocol) {
//        self.appendQueueCallback = appendQueueCallback
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
    
    
    public func updateSmallCameraBuffer(buffer: CMSampleBuffer, position: AVCaptureDevice.Position) {
        self.smallCameraView?.update(buffer: buffer, position: position)
    }
    
    public func updateMainCameraBuffer(buffer: CMSampleBuffer, position: AVCaptureDevice.Position) {
        self.mainCameraView?.update(buffer: buffer, position: position)
    }
    
    // Gesture Recognizer Delegate Method
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 두 제스처 인식기가 동시에 인식될 수 있도록 허용
        return true
    }
}

extension MultiCameraView: AppendQueueProtocol {
    func appendVideoQueue(pixelBuffer: CVPixelBuffer, time: CMTime, position: AVCaptureDevice.Position) {
        self.appendQueueCallback?.appendVideoQueue(pixelBuffer: pixelBuffer, time: time, position: position)
    }
    
    func appendAudioQueue(sampleBuffer: CMSampleBuffer) {
        self.appendQueueCallback?.appendAudioQueue(sampleBuffer: sampleBuffer)
    }
}
