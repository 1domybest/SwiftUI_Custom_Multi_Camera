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
            UIKitViewRepresentable(view: vm.cameraManager?.singleCameraView)
                .frame(height: (UIScreen.main.bounds.width / 9)  * 16 )
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer().frame(width: 15)
                            
                            Button(action: {
                                self.vm.switchScreenMode()
                            }, label: {
                                Circle()
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text("더블")
                                            .foregroundColor(.white)
                                    )
                            })
                            
                            Spacer()
                            Button(action: {
                                self.vm.toggleCameraPostion()
                            }, label: {
                                Circle()
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text("전면/후면")
                                            .foregroundColor(.white)
                                    )
                            })
                            Spacer().frame(width: 15)
                        }
                        Spacer().frame(height: 15)
                    }
                )
                .opacity(self.vm.cameraManager?.cameraViewMode == .singleScreen ? 1 : 0)
                .animation(.default)
            
            UIKitViewRepresentable(view: vm.cameraManager?.mainCameraView)
                .frame(height: (UIScreen.main.bounds.width / 9)  * 16 )
                .overlay(
                    VStack {
                        Spacer().frame(height: 15)
                        
                        HStack {
                            Spacer()
                            UIKitViewRepresentable(view: vm.cameraManager?.smallCameraView)
                                .frame(width: UIScreen.main.bounds.width / 4 ,height: ((UIScreen.main.bounds.width / 4) / 9)  * 16 )
                                .onTapGesture {
                                    self.vm.toggleMainCameraPostion()
                                }
                            
                            Spacer().frame(width: 15)
                        }
                        
                        Spacer()
                    }
                    
                )
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer().frame(width: 15)
                            Button(action: {
                                self.vm.switchScreenMode()
                            }, label: {
                                Circle()
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text("싱글")
                                            .foregroundColor(.white)
                                    )
                            })
                            Spacer()
                            Button(action: {
                                self.vm.toggleMainCameraPostion()
                            }, label: {
                                Circle()
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text("스왑")
                                            .foregroundColor(.white)
                                    )
                            })
                            Spacer().frame(width: 15)
                        }
                        Spacer().frame(height: 15)
                    }
                )
                .opacity(self.vm.cameraManager?.cameraViewMode == .doubleScreen ? 1 : 0)
                .animation(.default)
            
        }
        .onDisappear {
            self.vm.unreference()
        }
    }
}
