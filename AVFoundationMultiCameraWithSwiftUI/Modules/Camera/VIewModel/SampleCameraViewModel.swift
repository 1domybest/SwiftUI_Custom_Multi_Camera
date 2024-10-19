//
//  SampleCameraViewModel.swift
//  HypyG
//
//  Created by 온석태 on 10/2/24.
//

import Foundation


class SampleCameraViewModel: ObservableObject {
    var deviceMananger: DeviceMananger?
    @Published var isSingleScreenMode: Bool = false
    
    var isFrontCamera: Bool = false
    var isFrontMainCamera: Bool = false

    init() {
        self.deviceMananger = DeviceMananger()
    }
    
    deinit {
        print("SampleCameraViewModel deinit")
    }
    
    public func unreference() {
        self.deviceMananger?.unreference()
        self.deviceMananger = nil
    }
    
    func toggleCameraPostion () {
        self.isFrontCamera = self.deviceMananger?.cameraManager?.position == .front
        self.isFrontCamera.toggle()
        self.deviceMananger?.cameraManager?.setPosition(self.isFrontCamera ? .front : .back)
    }
    
    
    func toggleMainCameraPostion () {
        self.isFrontMainCamera = self.deviceMananger?.cameraManager?.mainCameraPostion == .front
        self.isFrontMainCamera.toggle()
        self.deviceMananger?.cameraManager?.switchMainCamera(mainCameraPostion: self.isFrontMainCamera ? .front : .back)
    }
    
    func switchScreenMode() {
        self.deviceMananger?.cameraManager?.setCameraViewMode(cameraViewMode: !self.isSingleScreenMode ? .singleScreen : .doubleScreen)
        self.isSingleScreenMode.toggle()
    }
    
}
