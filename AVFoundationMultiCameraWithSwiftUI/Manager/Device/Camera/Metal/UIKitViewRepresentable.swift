//
//  UIKitViewRepresentable.swift
//  HypyG
//
//  Created by 온석태 on 8/30/24.
//

import Foundation
import SwiftUI
import UIKit

struct UIKitViewRepresentable: UIViewRepresentable {
    let view: UIView?
    var width: CGFloat?
    var height: CGFloat?
    
    func makeUIView(context: Context) -> UIView {
        let uiView = UIView()
        return view ?? uiView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let width = width , let height = height else {
            return
        }
        uiView.frame.size = CGSize(width: width, height: height)
    }
}
