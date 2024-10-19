//
//  SampleCameraView.swift
//  HypyG
//
//  Created by 온석태 on 10/2/24.
//

import Foundation
import SwiftUI

struct SampleCameraView: View {
    @ObservedObject var vm: SampleCameraViewModel = SampleCameraViewModel()
    
    var body: some View {
        ZStack {
            UIKitViewRepresentable(view: vm.deviceMananger?.cameraManager?.singleCameraView)
                .frame(height: (UIScreen.main.bounds.width / 9)  * 16 )
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer().frame(width: 10)
                            
                            Button(action: {
                                self.vm.switchMultiSessionScreenMode()
                            }, label: {
                                Text("DoubleCamera")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor(.blue)
                                        
                                    )
                            })
                            .opacity(self.vm.cameraSessionMode == .multiSession ? 1 : 0)
                            
                            Spacer()
                            Button(action: {
                                self.vm.toggleSingleSessionCameraPostion()
                            }, label: {
                                Text("switchPostion")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor(.blue)
                                        
                                    )
                            })
                            Spacer().frame(width: 10)
                        }
                        Spacer().frame(height: 10)
                    }
                )
                .animation(.default)

            UIKitViewRepresentable(view: vm.deviceMananger?.cameraManager?.multiCameraView)
                .frame(height: (UIScreen.main.bounds.width / 9)  * 16 )
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer().frame(width: 10)
                            Button(action: {
                                self.vm.switchMultiSessionScreenMode()
                            }, label: {
                                Text("singleCamera")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor(.blue)
                                        
                                    )
                            })
                            Spacer()
                            Button(action: {
                                self.vm.toggleMultiSessionCameraPostion()
                            }, label: {
                                Text("switchCamera")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor(.blue)
                                        
                                    )
                            })
                            Spacer().frame(width: 10)
                        }
                        Spacer().frame(height: 10)
                    }
                )
                .opacity(self.vm.deviceMananger?.cameraManager?.cameraViewMode == .doubleScreen ? 1 : 0)
                .animation(.default)
                
        }
        .overlay (
            ZStack {
                VStack {
                    Spacer()
                    Button(action: {
                        if !self.vm.isRecording {
                            self.vm.deviceMananger?.singleRecordManager?.startVideoRecording()
                            if self.vm.cameraSessionMode == .multiSession && self.vm.cameraViewMode == .doubleScreen {
                                self.vm.deviceMananger?.doubleRecordManager?.startVideoRecording()
                            }
                            
                        } else {
                            self.vm.deviceMananger?.singleRecordManager?.stopVideoRecording()
                            if self.vm.cameraSessionMode == .multiSession && self.vm.cameraViewMode == .doubleScreen {
                                self.vm.deviceMananger?.doubleRecordManager?.stopVideoRecording()
                            }
                        }
//                        
                    }, label: {
                        Circle()
                            .frame(width: 50, height: 50)
                            .foregroundColor(!self.vm.isRecording ? Color.red : Color.blue)
                    })
                    
                    Spacer().frame(height: 150)
                }
            }
        )
        .onDisappear {
            self.vm.unreference()
        }
    }
}
