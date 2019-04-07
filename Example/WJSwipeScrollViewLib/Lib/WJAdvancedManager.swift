//
//  WJAdvancedManager.swift
//  WJScrollView_Example
//
//  Created by WJ on 2019/4/1.
//  Copyright © 2019年 WJ. All rights reserved.
//

import UIKit

@objc public protocol WJAdvancedScrollViewDelegate: class {
    @objc optional func wj_scrollViewOffsetY(_ offsetY: CGFloat)
}

public class WJAdvancedManager: UIView {
    
    public typealias WJAdvancedDidSelectIndexHandle = (Int) -> Void
    @objc public var advancedDidSelectIndexHandle: WJAdvancedDidSelectIndexHandle?
    @objc public weak var delegate: WJAdvancedScrollViewDelegate?
    
    //设置悬停位置Y值
    @objc public var hoverY: CGFloat = 0
    
    /* 点击切换滚动过程动画 */
    @objc public var isClickScrollAnimation = false {
        didSet {
            titleView.isClickScrollAnimation = isClickScrollAnimation
        }
    }
    
    /* 代码设置滚动到第几个位置 */
    @objc public func scrollToIndex(index: Int)  {
        pageView.scrollToIndex(index: index)
    }
    
    private var kHeaderHeight: CGFloat = 0.0
    private var currentSelectIndex: Int = 0
    private var lastDiffTitleToNav:CGFloat = 0.0
    private var headerView: UIView?
    private var viewControllers: [UIViewController]
    private var titles: [String]
    private weak var currentViewController: UIViewController?
    private var pageView: WJPageView!
    private var layout: WJLayout
    var isCustomTitleView: Bool = false
    
    private var titleView: WJPageTitleView!
    
    @objc public init(frame: CGRect, viewControllers: [UIViewController], titles: [String], currentViewController:UIViewController, layout: WJLayout, titleView: WJPageTitleView? = nil, headerViewHandle handle: () -> UIView) {
        UIScrollView.initializeOnce()
        UICollectionViewFlowLayout.loadOnce()
        self.viewControllers = viewControllers
        self.titles = titles
        self.currentViewController = currentViewController
        self.layout = layout
        super.init(frame: frame)
        UICollectionViewFlowLayout.wj_sliderHeight = layout.sliderHeight
        layout.isSinglePageView = true
        if titleView != nil {
            isCustomTitleView = true
            self.titleView = titleView!
        }else {
            self.titleView = setupTitleView()
        }
        self.titleView.isCustomTitleView = isCustomTitleView
        pageView = setupPageViewConfig(currentViewController: currentViewController, layout: layout, titleView: titleView)
        setupSubViewsConfig(handle)
    }
    
    deinit {
        deallocConfig()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WJAdvancedManager {
    private func setupTitleView() -> WJPageTitleView {
        let titleView = WJPageTitleView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: layout.sliderHeight), titles: titles, layout: layout)
        return titleView
    }
}


extension WJAdvancedManager {
    //MARK: 创建PageView
    private func setupPageViewConfig(currentViewController:UIViewController, layout: WJLayout, titleView: WJPageTitleView?) -> WJPageView {
        let pageView = WJPageView(frame: self.bounds, currentViewController: currentViewController, viewControllers: viewControllers, titles: titles, layout:layout, titleView: titleView)
        if titles.count != 0 {
            pageView.wj_createViewController(0)
        }
        DispatchQueue.main.after(0.01) {
            pageView.addSubview(self.titleView)
            pageView.setupGetPageViewScrollView(pageView, self.titleView)
        }
        return pageView
    }
}


extension WJAdvancedManager {
    
    private func setupSubViewsConfig(_ handle: () -> UIView) {
        let headerView = handle()
        kHeaderHeight = headerView.bounds.height
        self.headerView = headerView
        lastDiffTitleToNav = kHeaderHeight
        setupSubViews()
        addSubview(headerView)
    }
    
    private func setupSubViews() {
        titleView.frame.origin.y = kHeaderHeight
        backgroundColor = UIColor.white
        addSubview(pageView)
        setupPageViewDidSelectItem()
        setupFirstAddChildViewController()
        guard let viewController = viewControllers.first else { return }
        self.contentScrollViewScrollConfig(viewController)
        scrollInsets(viewController, kHeaderHeight+layout.sliderHeight)
    }
    
}


extension WJAdvancedManager {
    
    //设置ScrollView的contentInset
    private func scrollInsets(_ currentVC: UIViewController ,_ up: CGFloat) {
        currentVC.wj_scrollView?.contentInset = UIEdgeInsets(top: up, left: 0, bottom: 0, right: 0)
        currentVC.wj_scrollView?.scrollIndicatorInsets = UIEdgeInsets(top: up, left: 0, bottom: 0, right: 0)
    }
    
    //MARK: 首次创建pageView的ChildVC回调
    private func setupFirstAddChildViewController() {
        
        //首次创建pageView的ChildVC回调
        pageView.addChildVcBlock = {[weak self] in
            guard let `self` = self else { return }
            let currentVC = self.viewControllers[$0]
            
            //设置ScrollView的contentInset
            self.scrollInsets(currentVC, self.kHeaderHeight+self.layout.sliderHeight)
            //            self.scrollInsets(currentVC, 100)
            
            //初始化滚动回调 首次加载并不会执行内部方法
            self.contentScrollViewScrollConfig($1)
            
            //注意：节流---否则此方法无效。。
            self.setupFirstAddChildScrollView()
        }
    }
    
    func wj_adjustScrollViewContentSizeHeight(wj_scrollView: UIScrollView?) {
        guard let wj_scrollView = wj_scrollView else { return }
        //当前ScrollView的contentSize的高 = 当前ScrollView的的高 避免自动掉落
        let sliderH = self.layout.sliderHeight
        if wj_scrollView.contentSize.height < wj_scrollView.bounds.height - sliderH {
            wj_scrollView.contentSize.height = wj_scrollView.bounds.height - sliderH
        }
    }
    
    //MARK: 首次创建pageView的ChildVC回调 自适应调节
    private func setupFirstAddChildScrollView() {
        
        //注意：节流---否则此方法无效。。
        DispatchQueue.main.after(0.01, execute: {
            
            let currentVC = self.viewControllers[self.currentSelectIndex]
            
            guard let wj_scrollView = currentVC.wj_scrollView else { return }
            
            self.wj_adjustScrollViewContentSizeHeight(wj_scrollView: wj_scrollView)
            
            wj_scrollView.contentOffset.y = self.distanceBottomOffset()
            
            /*
             //当前ScrollView的contentSize的高
             let contentSizeHeight = wj_scrollView.contentSize.height
             
             //当前ScrollView的的高
             let boundsHeight = wj_scrollView.bounds.height - self.layout.sliderHeight
             
             //此处说明内容的高度小于bounds 应该让pageTitleView自动回滚到初始位置
             if contentSizeHeight <  boundsHeight {
             
             //为自动掉落加一个动画
             UIView.animate(withDuration: 0.12, animations: {
             //初始的偏移量 即初始的contentInset的值
             let offsetPoint = CGPoint(x: 0, y: -self.kHeaderHeight-self.layout.sliderHeight)
             
             //注意：此处调用此方法并不会执行scrollViewDidScroll:原因未可知
             wj_scrollView.setContentOffset(offsetPoint, animated: true)
             
             //在这里手动执行一下scrollViewDidScroll:事件
             self.setupwj_scrollViewDidScroll(scrollView: wj_scrollView, currentVC: currentVC)
             })
             
             
             }else {
             //首次初始化，通过改变当前ScrollView的偏移量，来确保ScrollView正好在pageTitleView下方
             wj_scrollView.contentOffset.y = self.distanceBottomOffset()
             }
             */
        })
        
    }
    
    //MARK: 当前的scrollView滚动的代理方法开始
    private func contentScrollViewScrollConfig(_ viewController: UIViewController) {
        
        viewController.wj_scrollView?.scrollHandle = {[weak self] scrollView in
            
            guard let `self` = self else { return }
            
            let currentVC = self.viewControllers[self.currentSelectIndex]
            
            guard currentVC.wj_scrollView == scrollView else { return }
            
            self.wj_adjustScrollViewContentSizeHeight(wj_scrollView: currentVC.wj_scrollView)
            
            self.setupwj_scrollViewDidScroll(scrollView: scrollView, currentVC: currentVC)
        }
    }
    
    //MARK: 当前控制器的滑动方法事件处理 1
    private func setupwj_scrollViewDidScroll(scrollView: UIScrollView, currentVC: UIViewController)  {
        
        //pageTitleView距离屏幕顶部到pageTitleView最底部的距离
        let distanceBottomOffset = self.distanceBottomOffset()
        
        //当前控制器上一次的偏移量
        let wj_upOffsetString = currentVC.wj_upOffset ?? String(describing: distanceBottomOffset)
        
        //先转化为Double(String转CGFloat步骤：String -> Double -> CGFloat)
        let wj_upOffsetDouble = Double(wj_upOffsetString) ?? Double(distanceBottomOffset)
        
        //再转化为CGFloat
        let wj_upOffset = CGFloat(wj_upOffsetDouble)
        
        //计算上一次偏移和当前偏移量y的差值
        let absOffset = scrollView.contentOffset.y - wj_upOffset
        
        //处理滚动
        self.contentScrollViewDidScroll(scrollView, absOffset)
        
        //记录上一次的偏移量
        currentVC.wj_upOffset = String(describing: scrollView.contentOffset.y)
    }
    
    
    //MARK: 当前控制器的滑动方法事件处理 2
    private func contentScrollViewDidScroll(_ contentScrollView: UIScrollView, _ absOffset: CGFloat)  {
        
        //获取当前控制器
        let currentVc = viewControllers[currentSelectIndex]
        
        //外部监听当前ScrollView的偏移量
        self.delegate?.wj_scrollViewOffsetY?((currentVc.wj_scrollView?.contentOffset.y ?? kHeaderHeight) + self.kHeaderHeight + layout.sliderHeight)
        
        //获取偏移量
        let offsetY = contentScrollView.contentOffset.y
        
        //获取当前pageTitleView的Y值
        var pageTitleViewY = titleView.frame.origin.y
        
        //pageTitleView从初始位置上升的距离
        let titleViewBottomDistance = offsetY + kHeaderHeight + layout.sliderHeight
        
        let headerViewOffset = titleViewBottomDistance + pageTitleViewY
        
        if absOffset > 0 && titleViewBottomDistance > 0 {//向上滑动
            if headerViewOffset >= kHeaderHeight {
                pageTitleViewY += -absOffset
                if pageTitleViewY <= hoverY {
                    pageTitleViewY = hoverY
                }
            }
        }else{//向下滑动
            if headerViewOffset < kHeaderHeight {
                pageTitleViewY = -titleViewBottomDistance + kHeaderHeight
                if pageTitleViewY >= kHeaderHeight {
                    pageTitleViewY = kHeaderHeight
                }
            }
        }
        
        titleView.frame.origin.y = pageTitleViewY
        headerView?.frame.origin.y = pageTitleViewY - kHeaderHeight
        let lastDiffTitleToNavOffset = pageTitleViewY - lastDiffTitleToNav
        lastDiffTitleToNav = pageTitleViewY
        //使其他控制器跟随改变
        for subVC in viewControllers {
            wj_adjustScrollViewContentSizeHeight(wj_scrollView: subVC.wj_scrollView)
            guard subVC != currentVc else { continue }
            guard let vcwj_scrollView = subVC.wj_scrollView else { continue }
            vcwj_scrollView.contentOffset.y += (-lastDiffTitleToNavOffset)
            subVC.wj_upOffset = String(describing: vcwj_scrollView.contentOffset.y)
        }
    }
    
    private func distanceBottomOffset() -> CGFloat {
        return -(titleView.frame.origin.y + layout.sliderHeight)
    }
}


extension WJAdvancedManager {
    
    //MARK: pageView选中事件
    private func setupPageViewDidSelectItem()  {
        
        pageView.didSelectIndexBlock = {[weak self] in
            
            guard let `self` = self else { return }
            
            self.setupUpViewControllerEndRefreshing()
            
            self.currentSelectIndex = $1
            
            self.advancedDidSelectIndexHandle?($1)
            
            self.setupContentSizeBoundsHeightAdjust()
            
        }
    }
    
    //MARK: 内容的高度小于bounds 应该让pageTitleView自动回滚到初始位置
    private func setupContentSizeBoundsHeightAdjust()  {
        
        DispatchQueue.main.after(0.01, execute: {
            
            let currentVC = self.viewControllers[self.currentSelectIndex]
            
            guard let wj_scrollView = currentVC.wj_scrollView else { return }
            
            self.wj_adjustScrollViewContentSizeHeight(wj_scrollView: wj_scrollView)
            
            //当前ScrollView的contentSize的高
            let contentSizeHeight = wj_scrollView.contentSize.height
            
            //当前ScrollView的的高
            let boundsHeight = wj_scrollView.bounds.height - self.layout.sliderHeight
            
            //此处说明内容的高度小于bounds 应该让pageTitleView自动回滚到初始位置
            //这里不用再进行其他操作，因为会调用ScrollViewDidScroll:
            if contentSizeHeight <  boundsHeight {
                let offsetPoint = CGPoint(x: 0, y: -self.kHeaderHeight-self.layout.sliderHeight)
                wj_scrollView.setContentOffset(offsetPoint, animated: true)
            }
        })
    }
    
    //MARK: 处理下拉刷新的过程中切换导致的问题
    private func setupUpViewControllerEndRefreshing() {
        //如果正在下拉，则在切换之前把上一个的ScrollView的偏移量设置为初始位置
        DispatchQueue.main.after(0.01) {
            let upVC = self.viewControllers[self.currentSelectIndex]
            guard let wj_scrollView = upVC.wj_scrollView else { return }
            //判断是下拉
            if wj_scrollView.contentOffset.y < (-self.kHeaderHeight-self.layout.sliderHeight) {
                let offsetPoint = CGPoint(x: 0, y: -self.kHeaderHeight-self.layout.sliderHeight)
                wj_scrollView.setContentOffset(offsetPoint, animated: true)
            }
        }
    }
    
}

extension WJAdvancedManager {
    private func deallocConfig() {
        for viewController in viewControllers {
            viewController.wj_scrollView?.delegate = nil
        }
    }
}
