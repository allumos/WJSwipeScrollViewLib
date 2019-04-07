//
//  WJPageView.swift
//  WJScrollView
//
//  Created by WJ on 2019/4/1.
//  Copyright © 2019年 WJ. All rights reserved.
//

import UIKit

public typealias PageViewDidSelectIndexBlock = (WJPageView, Int) -> Void
public typealias AddChildViewControllerBlock = (Int, UIViewController) -> Void

@objc public protocol WJPageViewDelegate: class {
    @objc optional func wj_scrollViewDidScroll(_ scrollView: UIScrollView)
    @objc optional func wj_scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    @objc optional func wj_scrollViewWillBeginDecelerating(_ scrollView: UIScrollView)
    @objc optional func wj_scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    @objc optional func wj_scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    @objc optional func wj_scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
}

public class WJPageView: UIView {
    
    private weak var currentViewController: UIViewController?
    private var viewControllers: [UIViewController]
    private var titles: [String]
    private var layout: WJLayout = WJLayout()
    private var wj_currentIndex: Int = 0;
    
    @objc public var didSelectIndexBlock: PageViewDidSelectIndexBlock?
    @objc public var addChildVcBlock: AddChildViewControllerBlock?
    
    /* 点击切换滚动过程动画  */
    @objc public var isClickScrollAnimation = false {
        didSet {
            pageTitleView.isClickScrollAnimation = isClickScrollAnimation
        }
    }
    
    /* pageView的scrollView左右滑动监听 */
    @objc public weak var delegate: WJPageViewDelegate?
    
    var isCustomTitleView: Bool = false
    
    var pageTitleView: WJPageTitleView!
    
    @objc public lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
        scrollView.contentSize = CGSize(width: self.bounds.width * CGFloat(self.titles.count), height: 0)
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.bounces = layout.isShowBounces
        scrollView.isScrollEnabled = layout.isScrollEnabled
        scrollView.showsHorizontalScrollIndicator = layout.showsHorizontalScrollIndicator
        return scrollView
    }()
    
    
    @objc public init(frame: CGRect, currentViewController: UIViewController, viewControllers:[UIViewController], titles: [String], layout: WJLayout, titleView: WJPageTitleView? = nil) {
        self.currentViewController = currentViewController
        self.viewControllers = viewControllers
        self.titles = titles
        self.layout = layout
        guard viewControllers.count == titles.count else {
            fatalError("控制器数量和标题数量不一致")
        }
        super.init(frame: frame)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        if titleView != nil {
            isCustomTitleView = true
            self.pageTitleView = titleView!
        }else {
            self.pageTitleView = setupTitleView()
        }
        self.pageTitleView.isCustomTitleView = isCustomTitleView
        setupSubViews()
    }
    
    /* 滚动到某个位置 */
    @objc public func scrollToIndex(index: Int)  {
        pageTitleView.scrollToIndex(index: index)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension WJPageView {
    
    private func setupSubViews()  {
        addSubview(scrollView)
        if layout.isSinglePageView == false {
            addSubview(pageTitleView)
            wj_createViewController(0)
            setupGetPageViewScrollView(self, pageTitleView)
        }
    }
    
}

extension WJPageView {
    private func setupTitleView() -> WJPageTitleView {
        let pageTitleView = WJPageTitleView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.layout.sliderHeight), titles: titles, layout: layout)
        pageTitleView.backgroundColor = self.layout.titleViewBgColor
        return pageTitleView
    }
}

extension WJPageView {
    func setupGetPageViewScrollView(_ pageView:WJPageView, _ titleView: WJPageTitleView) {
        pageView.delegate = titleView
        titleView.mainScrollView = pageView.scrollView
        titleView.scrollIndexHandle = pageView.currentIndex
        titleView.wj_createViewControllerHandle = {[weak pageView] index in
            pageView?.wj_createViewController(index)
        }
        titleView.wj_didSelectTitleViewHandle = {[weak pageView] index in
            pageView?.didSelectIndexBlock?((pageView)!, index)
        }
    }
}

extension WJPageView {
    
    public func wj_createViewController(_ index: Int)  {
        let VC = viewControllers[index]
        guard let currentViewController = currentViewController else { return }
        if currentViewController.children.contains(VC) {
            return
        }
        var viewControllerY: CGFloat = 0.0
        layout.isSinglePageView ? viewControllerY = 0.0 : (viewControllerY = layout.sliderHeight)
        VC.view.frame = CGRect(x: scrollView.bounds.width * CGFloat(index), y: viewControllerY, width: scrollView.bounds.width, height: scrollView.bounds.height)
        scrollView.addSubview(VC.view)
        currentViewController.addChild(VC)
        VC.automaticallyAdjustsScrollViewInsets = false
        addChildVcBlock?(index, VC)
        if let wj_scrollView = VC.wj_scrollView {
            if #available(iOS 11.0, *) {
                wj_scrollView.contentInsetAdjustmentBehavior = .never
            }
            wj_scrollView.frame.size.height = wj_scrollView.frame.size.height - viewControllerY
        }
    }
    
    public func currentIndex() -> Int {
        if scrollView.bounds.width == 0 || scrollView.bounds.height == 0 {
            return 0
        }
        let index = Int((scrollView.contentOffset.x + scrollView.bounds.width * 0.5) / scrollView.bounds.width)
        return max(0, index)
    }
    
}

extension WJPageView {
    
    private func getRGBWithColor(_ color : UIColor) -> (CGFloat, CGFloat, CGFloat) {
        guard let components = color.cgColor.components else {
            fatalError("请使用RGB方式给标题颜色赋值")
        }
        return (components[0] * 255, components[1] * 255, components[2] * 255)
    }
}

extension UIColor {
    
    public convenience init(r : CGFloat, g : CGFloat, b : CGFloat) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1.0)
    }
}

extension WJPageView: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.wj_scrollViewDidScroll?(scrollView)
        if isCustomTitleView {
            let index = currentIndex()
            if wj_currentIndex != index {
                wj_createViewController(index)
                didSelectIndexBlock?(self, index)
                wj_currentIndex = index
            }
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.wj_scrollViewWillBeginDragging?(scrollView)
    }
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        delegate?.wj_scrollViewWillBeginDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.wj_scrollViewDidEndDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.wj_scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.wj_scrollViewDidEndScrollingAnimation?(scrollView)
        
    }
}


