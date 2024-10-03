//
//  Environment+NavigationController.swift
//  HypyG
//
//  Created by 윤예진 on 12/6/23.
//

import Foundation
import SwiftUI

/**
 환경 변수 + 네비게이션
 */

var viewNameKey: UInt8 = 0
var viewPkKey: UInt8 = 0
var isSwipeEnableKey: UInt8 = 0
var isReplacedKey: UInt8 = 0
var contentIdKey: UInt8 = 0

private struct NavigationControllerKey: EnvironmentKey {
    static let defaultValue: NavigationController? = nil
}

private struct ViewPk: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

private struct ContentId: EnvironmentKey {
    static let defaultValue: String? = ""
}

extension EnvironmentValues {
    var navigationController: NavigationController? {
        get { self[NavigationControllerKey.self] }
        set { self[NavigationControllerKey.self] = newValue }
    }
    
    var viewPK: UUID? {
        get { self[ViewPk.self] }
        set { self[ViewPk.self] = newValue }
    }
    
    var contentId: String? {
        get { self[ContentId.self] }
        set { self[ContentId.self] = newValue }
    }
}

extension View {
    func envNavigation(_ navigationController: NavigationController?) -> some View {
        environment(\.navigationController, navigationController)
    }
}
