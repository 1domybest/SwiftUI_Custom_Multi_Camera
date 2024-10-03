//
//  CustomNavigationController.swift
//  UIkit+SwiftUI
//
//  Created by 온석태 on 10/3/24.
//

import Foundation
import UIKit


class CustomNavigationController: UINavigationController, UINavigationControllerDelegate {
    var shouldPushViewController: ((UIViewController) -> Bool)?
    var callbackList: [(NavigationCallbackProtocol, UUID)] = []

    
    deinit {
        print("CustomNavigationController Deinit")
    }
    
    func deinitialize() {
        for viewController in self.viewControllers {
            let viewName = viewController.viewName ?? .None
            let viewPk = viewController.viewPk ?? UUID()
            let isSwipeEnable = viewController.isSwipeEnable ?? false
            
            for (index, (callback, pk)) in self.callbackList.enumerated().reversed() {
                if viewPk == pk {
                    self.callbackList.remove(at: index)
                    callback.didPop(viewName: viewName, isSwipe: isSwipeEnable, viewPk: viewPk)
                }
            }
            
        }
        
        self.callbackList.removeAll()
    }
    
    func setCallback(callback: NavigationCallbackProtocol, viewPk: UUID) {
        if !callbackList.contains(where: { $0.1 == viewPk }) {
            callbackList.append((callback, viewPk))
            print("콜백 추가됨, 갯수 \(callbackList.count)")
        } else {
            print("콜백 이미 존재하는 UUID입니다. 추가하지 않음.")
        }

        print("콜백 내용 \(callbackList)")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? .portrait
    }

    override var shouldAutorotate: Bool {
        topViewController?.shouldAutorotate ?? true
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if let fromViewController = transitionCoordinator?.viewController(forKey: .from),
           !navigationController.viewControllers.contains(fromViewController) {
            let isSwipeEnable = fromViewController.isSwipeEnable ?? false

            // 실제로 pop이 완료된 상태일 때만 호출
            let viewName = fromViewController.viewName ?? .None
            let viewPk = fromViewController.viewPk ?? UUID()

            for (index, (callback, pk)) in self.callbackList.enumerated().reversed() {
                if viewPk == pk {
                    self.callbackList.remove(at: index)
                    callback.didPop(viewName: viewName, isSwipe: isSwipeEnable, viewPk: viewPk)
                }
            }
        }
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        var viewControllers = viewControllers
        let replacedControllerView = viewControllers.removeLast()

        let viewName = replacedControllerView.viewName ?? .None
        let viewPk = replacedControllerView.viewPk ?? UUID()
        let isSwipe = replacedControllerView.isSwipeEnable ?? false

        for (index, (callback, pk)) in self.callbackList.enumerated().reversed() {
            if viewPk == pk {
                self.callbackList.remove(at: index)
                callback.didPop(viewName: viewName, isSwipe: isSwipe, viewPk: viewPk)
            }
        }
        super.setViewControllers(viewControllers, animated: animated)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let poppedViewController = super.popViewController(animated: animated)
        let isSwipeEnable = poppedViewController?.isSwipeEnable ?? false

        if !isSwipeEnable {
            let viewName = poppedViewController?.viewName ?? .None
            let viewPk = poppedViewController?.viewPk ?? UUID()
            let isSwipe = poppedViewController?.isSwipeEnable ?? false

            for (index, (callback, pk)) in self.callbackList.enumerated().reversed() {
                if viewPk == pk {
                    self.callbackList.remove(at: index)
                    callback.didPop(viewName: viewName, isSwipe: isSwipe, viewPk: viewPk)
                }
            }
        }


        return poppedViewController
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
         if let shouldPush = shouldPushViewController {
             if !shouldPush(viewController) {
                 return
             }
         } else if !viewController.shouldPush() {
             return
         }

         if let topViewController = self.topViewController,
            let topViewName = topViewController.viewName,
            let newViewName = viewController.viewName,
            topViewName == newViewName {
             if DoublePushViewName(rawValue: newViewName.rawValue) != nil {
                 return
             }
         }

         super.pushViewController(viewController, animated: animated)
     }
}
