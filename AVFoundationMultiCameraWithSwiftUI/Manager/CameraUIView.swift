//
//  CameraUIView.swift
//  HypyG
//
//  Created by 온석태 on 10/2/24.
//

import Foundation
import SwiftUI
import UIKit

struct CameraUIView: UIViewRepresentable {
    let view:CameraMetalView?
    
    public func makeUIView(context _: Context) -> UIView {
        return view ?? UIView()
    }

    public func updateUIView(_: UIView, context _: Context) {}
}
