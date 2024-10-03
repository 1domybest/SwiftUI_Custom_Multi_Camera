//
//  NavigationCallbackProtocol.swift
//  HypyG
//
//  Created by 온석태 on 6/13/24.
//

import Foundation


protocol NavigationCallbackProtocol {
    func didPop(viewName: ViewName, isSwipe: Bool, viewPk: UUID)
}
