//
//  CustomHostingController.swift
//  UIkit+SwiftUI
//
//  Created by 온석태 on 10/3/24.
//

import Foundation
import SwiftUI
import UIKit

class CustomHostingController<Content>: UIHostingController<Content> where Content: View {

    override init(rootView: Content) {
        super.init(rootView: rootView)
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }
}

