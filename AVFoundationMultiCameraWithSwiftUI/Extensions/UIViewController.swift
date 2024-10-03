//
//  UIViewController.swift
//  UIkit+SwiftUI
//
//  Created by 온석태 on 10/3/24.
//

import Foundation
import UIKit


extension UIViewController {
    
    @objc func shouldPush() -> Bool {
        return true
    }
    
    var viewName: ViewName? {
        get {
            return objc_getAssociatedObject(self, &viewNameKey) as? ViewName
        }
        set {
            objc_setAssociatedObject(self, &viewNameKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var viewPk: UUID? {
        get {
            return objc_getAssociatedObject(self, &viewPkKey) as? UUID
        }
        set {
            objc_setAssociatedObject(self, &viewPkKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var isSwipeEnable: Bool? {
        get {
            return objc_getAssociatedObject(self, &isSwipeEnableKey) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &isSwipeEnableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var isReplaced: Bool? {
        get {
            return objc_getAssociatedObject(self, &isReplacedKey) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &isReplacedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var contentId: String? {
        get {
            return objc_getAssociatedObject(self, &contentIdKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &contentIdKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
