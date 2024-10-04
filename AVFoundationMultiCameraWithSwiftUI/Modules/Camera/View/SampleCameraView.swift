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
                            Spacer().frame(width: 10)
                            
                            Button(action: {
                                self.vm.switchScreenMode()
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
                            
                            Spacer()
                            Button(action: {
                                self.vm.toggleCameraPostion()
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

            UIKitViewRepresentable(view: vm.cameraManager?.multiCameraView)
                .frame(height: (UIScreen.main.bounds.width / 9)  * 16 )
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer().frame(width: 10)
                            Button(action: {
                                self.vm.switchScreenMode()
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
                                self.vm.toggleMainCameraPostion()
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
                .opacity(self.vm.cameraManager?.cameraViewMode == .doubleScreen ? 1 : 0)
                .animation(.default)
                
        }
        .onDisappear {
            self.vm.unreference()
        }
    }
}
