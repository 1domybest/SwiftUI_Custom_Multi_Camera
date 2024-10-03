//
//  ContentView.swift
//  SwiftUIWithUIKit
//
//  Created by 온석태 on 2023/10/19.
//

import SwiftUI

struct ContentView: View {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate // register app delegate for Firebase setup
    
    @Environment(\.navigationController) var navigationController: NavigationController? // 네비게이션
    
    var body: some View {
        ZStack {
            Button(action: {
                self.navigationController?.push(SampleCameraView(), animated: true, viewName: .None)
            }, label: {
                Text("go to camera")
            })
        }
    }
}
