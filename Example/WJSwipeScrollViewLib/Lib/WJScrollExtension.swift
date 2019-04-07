//
//  WJScrollExtension.swift
//  WJScrollView
//
//  Created by WJ on 2019/4/1.
//  Copyright © 2019年 WJ. All rights reserved.
//

import Foundation
import UIKit

extension UIScrollView {
    
    public typealias WJScrollHandle = (UIScrollView) -> Void
    
    private struct LTHandleKey {
        static var key = "wj_handle"
        static var tKey = "wj_isTableViewPlain"
    }
    
    public var scrollHandle: WJScrollHandle? {
        get { return objc_getAssociatedObject(self, &LTHandleKey.key) as? WJScrollHandle }
        set { objc_setAssociatedObject(self, &LTHandleKey.key, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
    
    @objc public var isTableViewPlain: Bool {
        get { return (objc_getAssociatedObject(self, &LTHandleKey.tKey) as? Bool) ?? false}
        set { objc_setAssociatedObject(self, &LTHandleKey.tKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
}

extension String {
    func wj_base64Decoding() -> String {
        let decodeData = NSData.init(base64Encoded: self, options: NSData.Base64DecodingOptions.init(rawValue: 0))
        if decodeData == nil || decodeData?.length == 0 {
            return "";
        }
        let decodeString = NSString(data: decodeData! as Data, encoding: String.Encoding.utf8.rawValue)
        return decodeString! as String
    }
}

extension UIScrollView {
    
    public class func initializeOnce() {
        DispatchQueue.once(token: UIDevice.current.identifierForVendor?.uuidString ?? "WJScrollView") {
            let didScroll = "X25vdGlmeURpZFNjcm9sbA==".wj_base64Decoding()
            let originSelector = Selector((didScroll))
            let swizzleSelector = #selector(wj_scrollViewDidScroll)
            wj_swizzleMethod(self, originSelector, swizzleSelector)
        }
    }
    
    @objc dynamic func wj_scrollViewDidScroll() {
        self.wj_scrollViewDidScroll()
        guard let scrollHandle = scrollHandle else { return }
        scrollHandle(self)
    }
}

extension NSObject {
    
    static func wj_swizzleMethod(_ cls: AnyClass?, _ originSelector: Selector, _ swizzleSelector: Selector)  {
        let originMethod = class_getInstanceMethod(cls, originSelector)
        let swizzleMethod = class_getInstanceMethod(cls, swizzleSelector)
        guard let swMethod = swizzleMethod, let oMethod = originMethod else { return }
        let didAddSuccess: Bool = class_addMethod(cls, originSelector, method_getImplementation(swMethod), method_getTypeEncoding(swMethod))
        if didAddSuccess {
            class_replaceMethod(cls, swizzleSelector, method_getImplementation(oMethod), method_getTypeEncoding(oMethod))
        } else {
            method_exchangeImplementations(oMethod, swMethod)
        }
    }
}




