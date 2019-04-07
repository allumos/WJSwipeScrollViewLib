//
//  LTCollectionFlowLayout.swift
//  WJScrollView_Example
//
//  Created by WJ on 2019/4/1.
//  Copyright © 2019年 WJ. All rights reserved.
//

import UIKit

extension UICollectionViewFlowLayout {
    
    private struct WJCollectionViewHandleKey {
        static var key = "wj_collectionViewContentSizeHandle"
    }
    
    public static var wj_sliderHeight: CGFloat? {
        get { return objc_getAssociatedObject(self, &WJCollectionViewHandleKey.key) as? CGFloat }
        set { objc_setAssociatedObject(self, &WJCollectionViewHandleKey.key, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    public class func loadOnce() {
        DispatchQueue.once(token: "WJFlowLayout") {
            let originSelector = #selector(getter: UICollectionViewLayout.collectionViewContentSize)
            let swizzleSelector = #selector(UICollectionViewFlowLayout.wj_collectionViewContentSize)
            wj_swizzleMethod(self, originSelector, swizzleSelector)
        }
    }
    
    @objc dynamic func wj_collectionViewContentSize() -> CGSize {
        
        let contentSize = self.wj_collectionViewContentSize()
        
        guard let collectionView = collectionView else { return contentSize }
        
        guard let wj_sliderHeight = UICollectionViewFlowLayout.wj_sliderHeight, wj_sliderHeight > 0 else { return contentSize }
        
        let collectionViewH = collectionView.bounds.height - wj_sliderHeight
        
        return contentSize.height < collectionViewH ? CGSize(width: contentSize.width, height: collectionViewH) : contentSize
    }
}
