//
//  SampleCameraViewModel.swift
//  HypyG
//
//  Created by 온석태 on 10/2/24.
//

import Foundation


class SampleCameraViewModel: ObservableObject {
    var cameraManager: CameraManager?
    @Published var isSingleScreenMode: Bool = false
    
    var isFrontCamera: Bool = false
    var isFrontMainCamera: Bool = false

    init() {
        self.cameraManager = CameraManager(cameraViewMode: .doubleScreen)
    }
    
    deinit {
        print("SampleCameraViewModel deinit")
    }
    
    public func unreference() {
        self.cameraManager?.unreference()
        self.cameraManager = nil
    }
    
    func toggleCameraPostion () {
        self.isFrontCamera = self.cameraManager?.position == .front
        self.isFrontCamera.toggle()
        self.cameraManager?.setPosition(self.isFrontCamera ? .front : .back)
    }
    
    
    func toggleMainCameraPostion () {
        self.isFrontMainCamera = self.cameraManager?.mainCameraPostion == .front
        self.isFrontMainCamera.toggle()
        self.cameraManager?.switchMainCamera(mainCameraPostion: self.isFrontMainCamera ? .front : .back)
    }
    
    func switchScreenMode() {
        self.cameraManager?.setCameraViewMode(cameraViewMode: !self.isSingleScreenMode ? .singleScreen : .doubleScreen)
        self.isSingleScreenMode.toggle()
    }
    
}
