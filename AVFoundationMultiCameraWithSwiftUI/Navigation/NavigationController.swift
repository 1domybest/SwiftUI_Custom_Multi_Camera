//
//  NavigationController.swift
//  SwiftUIWithUIKit
//
//  Created by 온석태 on 2023/10/19.
//

import SwiftUI
import UIKit

///
/// 네비게이션 컨트롤러
///
/// - Parameters:
/// - Returns:
///
final class NavigationController: NSObject {

    private let window: UIWindow
    var rootViewController:CustomNavigationController?
    
    init(window: UIWindow) {
        self.window = window
    }
    
    ///
    /// 앱 첫시작시 실행되는 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func showRootView() {
        setRootView(ContentView(), animated: true, viewName: .ContentView)
    }
    
    func setCallback (callback: NavigationCallbackProtocol, viewPk: UUID) {
        self.rootViewController?.setCallback(callback: callback, viewPk: viewPk)
    }
    
    ///
    /// 최상단 부모 viewController 지정함수
    ///
    /// - Parameters:
    ///    - view ( T ) : SwiftUI View
    ///    - animated ( Bool ) : 화면전환 애니메이션 유무
    /// - Returns:
    ///
    func setRootView<T: View>(_ view: T, animated _: Bool, viewName: ViewName, contentId: String? = nil) {
        if self.rootViewController != nil {
            self.rootViewController?.deinitialize()
        }
        
        
        let viewPk = UUID()
        let view = view
            .environment(\.navigationController, self)
            .environment(\.viewPK, viewPk)
            .environment(\.contentId, contentId)
            .navigationBarHidden(true)
            .ignoresSafeArea(.all)
        
        let hostingView = CustomHostingController(rootView: view)
        hostingView.navigationItem.hidesBackButton = true
        
        hostingView.viewName = viewName
        hostingView.viewPk = viewPk
        hostingView.contentId = contentId
        
        
        let customNavController = CustomNavigationController(rootViewController: hostingView)
        
        
        customNavController.interactivePopGestureRecognizer?.delegate = self
        customNavController.delegate = customNavController

        self.rootViewController = customNavController
        
        window.rootViewController = customNavController
        
    }
  
    ///
    /// UIKit 의 ViewController 를 직접 push 하는 함수
    ///
    /// - Parameters:
    ///    - viewController ( UIViewController ) : UIKitt ViewController
    ///    - animated ( Bool ) : 화면전환 애니메이션 유무
    /// - Returns:
    ///
    func push(viewController: UIViewController, animated: Bool, swipeActivation: Bool = true, viewName: ViewName, contentId: String? = nil) {
        
        if !self.validateDoubleNavigation(viewName: viewName, contentId: contentId) {
            self.pop()
            return
        }
        
        if let navigationController = window.rootViewController as? CustomNavigationController {
            let viewPk = UUID()
            
            viewController.viewName = viewName
            viewController.viewPk = viewPk
            viewController.contentId = contentId
            viewController.isSwipeEnable = swipeActivation

            navigationController.setToolbarHidden(true, animated: true)
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.pushViewController(viewController, animated: animated)
        }
    }

    
    ///
    /// SwiftUI 의 View 를 변환후 직접 push 하는 함수
    ///
    /// - Parameters:
    ///    - view ( T ) : UIKitt SwiftUI View
    ///    - animated ( Bool ) : 화면전환 애니메이션 유무
    /// - Returns:
    ///
    func push<T: View>(_ view: T, animated: Bool, swipeActivation: Bool = true, viewName: ViewName, contentId: String? = nil) {
        if !self.validateDoubleNavigation(viewName: viewName, contentId: contentId) {
            self.pop()
            return
        }
        
        let viewPk = UUID()
        let view = view
            .environment(\.navigationController, self)
            .environment(\.viewPK, viewPk)
            .environment(\.contentId, contentId)
            .navigationBarHidden(true)
            .ignoresSafeArea(.all)
        
        let hostingView = CustomHostingController(rootView: view.environment(\.navigationController, self).navigationBarHidden(true).ignoresSafeArea(.all))
        hostingView.navigationItem.hidesBackButton = true
        
        hostingView.viewName = viewName
        hostingView.viewPk = viewPk
        hostingView.contentId = contentId
        hostingView.isSwipeEnable = swipeActivation

        if let navigationController = self.rootViewController {
            navigationController.setToolbarHidden(true, animated: true)
            navigationController.setNavigationBarHidden(true, animated: false)

            navigationController.pushViewController(hostingView, animated: animated)
        }
    }
    
    func validateDoubleNavigation (viewName: ViewName, contentId: String? = nil) -> Bool {
        guard let contentId = contentId else { return true }
        
        if let previousViewController = self.getPreviousViewController() {
            let beforeContentId = previousViewController.contentId
            let beforeViewName = previousViewController.viewName
            var viewName = viewName

            if beforeViewName == viewName && beforeContentId == contentId {
                return false
            }

        }
        
        return true
    }
    
    func getPreviousViewController() -> UIViewController? {
        if let navigationController = self.rootViewController {
            let viewControllers = navigationController.viewControllers
            if viewControllers.count > 1 {
                return viewControllers[viewControllers.count - 2]
            }
        }
        return nil
    }
    
    func getCurrentViewController() -> UIViewController? {
        if let topViewController = self.rootViewController?.topViewController {
            return topViewController
        }

        return nil
    }

    func replaceTopView<T: View>(_ view: T, animated: Bool, swipeActivation: Bool = true, viewName: ViewName, contentId: String? = nil) {
        
        if !self.validateDoubleNavigation(viewName: viewName, contentId: contentId) {
            self.pop()
            return
        }
        
        let viewPk = UUID()
        let view = view
            .environment(\.navigationController, self)
            .environment(\.viewPK, viewPk)
            .environment(\.contentId, contentId)
            .navigationBarHidden(true)
            .ignoresSafeArea(.all)
        
        let hostingView = CustomHostingController(rootView: view)
        hostingView.navigationItem.hidesBackButton = true
        
        hostingView.viewName = viewName
        hostingView.viewPk = viewPk
        hostingView.contentId = contentId
        hostingView.isSwipeEnable = swipeActivation

        if let navigationController = self.rootViewController {
            
            var viewControllers = navigationController.viewControllers

            let replacedControllerView = viewControllers.removeLast()
            replacedControllerView.isReplaced = true

            viewControllers.append(hostingView)
            viewControllers.append(replacedControllerView)

            navigationController.setViewControllers(viewControllers, animated: animated)
        }
    }
    
    func replaceTopView<T: View>(_ view: T, type: CATransitionSubtype, animationType: CATransitionType = .moveIn, swipeActivation: Bool = true, viewName: ViewName, contentId: String? = nil) {
        
        if !self.validateDoubleNavigation(viewName: viewName, contentId: contentId) {
            self.pop()
            return
        }
        
        let viewPk = UUID()
        let view = view
            .environment(\.navigationController, self)
            .environment(\.viewPK, viewPk)
            .environment(\.contentId, contentId)
            .navigationBarHidden(true)
            .ignoresSafeArea(.all)
        
        let hostingView = CustomHostingController(rootView: view)
        hostingView.navigationItem.hidesBackButton = true
        
        hostingView.viewName = viewName
        hostingView.viewPk = viewPk
        hostingView.contentId = contentId
        hostingView.isReplaced = true
        hostingView.isSwipeEnable = swipeActivation

        if let navigationController = self.rootViewController {
            
            let transition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            transition.type = animationType
            transition.subtype = type
            navigationController.view.layer.add(transition, forKey: kCATransition)
            
            var viewControllers = navigationController.viewControllers
            
            let replacedControllerView = viewControllers.removeLast()
            replacedControllerView.isReplaced = true

            viewControllers.append(hostingView)
            viewControllers.append(replacedControllerView)

            navigationController.setViewControllers(viewControllers, animated: false)
        }
    }


    ///
    /// SwiftUI 의 View 를 변환후 직접 push 하는 함수 + 화면전환 방향 커스텀 지정
    ///
    /// - Parameters:
    ///    - view ( T ) : UIKitt SwiftUI View
    ///    - animated ( Bool ) : 화면전환 애니메이션 유무
    ///    - type ( CATransitionSubtype ) : 화면전환 방향
    /// - Returns:
    ///
    func push<T: View>(_ view: T, animated _: Bool, type: CATransitionSubtype, animationType: CATransitionType = .moveIn, swipeActivation: Bool = true, viewName: ViewName, contentId: String? = nil) {
        
        if !self.validateDoubleNavigation(viewName: viewName, contentId: contentId) {
            self.pop()
            return
        }
        
        let viewPk = UUID()
        let view = view
            .environment(\.navigationController, self)
            .environment(\.viewPK, viewPk)
            .environment(\.contentId, contentId)
            .navigationBarHidden(true)
            .ignoresSafeArea(.all)
        
        let hostingView = UIHostingController(rootView: view)
        
        hostingView.navigationItem.hidesBackButton = true
        
        hostingView.viewName = viewName
        hostingView.viewPk = viewPk
        hostingView.contentId = contentId
        hostingView.isSwipeEnable = swipeActivation

        if let navigationController = self.rootViewController {
            navigationController.isNavigationBarHidden = true
            let transition = CATransition()
            transition.duration = 0.3
            transition
                .timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            transition.type = animationType
            transition.subtype = type
            navigationController.view.layer.add(transition, forKey: kCATransition)
                
            navigationController.pushViewController(hostingView, animated: false)
        }
    }
    
    ///
    /// 네비게이션 pop 하는 함수 + 화면전환 방향 커스텀 지정
    ///
    /// - Parameters:
    ///    - type ( CATransitionSubtype ) : 화면전환 방향
    /// - Returns:
    ///
    func pop(type: CATransitionSubtype) {
        if let navigationController = self.rootViewController {
            let transition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            transition.type = CATransitionType.reveal
            transition.subtype = type
            navigationController.view.layer.add(transition, forKey: kCATransition)
            let _ = navigationController.popViewController(animated: false)
        }
    }
    
    ///
    /// 네비게이션 pop 하는 함수
    ///
    /// - Parameters:
    /// - Returns:
    ///
    func pop() {
        if let navigationController = self.rootViewController {
            let _ = navigationController.popViewController(animated: true)
        }
    }
    
    ///
    /// 네비게이션 최상단 부모 컨트롤러로 한번에 pop 하는 함수
    ///
    /// - Parameters:
    ///    - animated ( Bool ) : 화면전환 애니메이션 유무
    /// - Returns:
    ///
    func popToRoot(animated: Bool) {
        if let navigationController = self.rootViewController {
            navigationController.popToRootViewController(animated: animated)
        }
    }
}

extension NavigationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer, let view = panGestureRecognizer.view {
            let velocity = panGestureRecognizer.velocity(in: view)
            let isHorizontalSwipe = abs(velocity.x) > abs(velocity.y)
            
            if isHorizontalSwipe {
                let isSwipeEnable = self.getCurrentViewController()?.isSwipeEnable ?? false
                return isSwipeEnable
            } else {
                return false
            }
        }
        return false
    }
}


