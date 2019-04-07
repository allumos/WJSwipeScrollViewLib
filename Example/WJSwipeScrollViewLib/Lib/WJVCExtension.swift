//
//  LTVCExtension.swift
//  WJScrollView
//
//  Created by WJ on 2019/4/1.
//  Copyright © 2019年 WJ. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    private struct LTVCKey {
        static var sKey = "wj_scrollViewKey"
        static var oKey = "wj_upOffsetKey"
    }
    
    @objc public var wj_scrollView: UIScrollView? {
        get { return objc_getAssociatedObject(self, &LTVCKey.sKey) as? UIScrollView }
        set { objc_setAssociatedObject(self, &LTVCKey.sKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    public var wj_upOffset: String? {
        get { return objc_getAssociatedObject(self, &LTVCKey.oKey) as? String }
        set { objc_setAssociatedObject(self, &LTVCKey.oKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

