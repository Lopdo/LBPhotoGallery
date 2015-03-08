//
//  LBPhotoGalleryView.swift
//  LBPhotoGalleryExample
//
//  Created by Jan Kosa on 06/03/15.
//  Copyright (c) 2015 Jan Kosa. All rights reserved.
//

import UIKit

enum LBPhotoGalleryMode
{
	case ImageLocal
	case ImageRemote
	case CustomView
}

enum LBPhotoCaptionStyle
{
	case PlainText
	case AttributedText
	case CustomView
}

enum LBPhotoGalleryDoubleTapHandler: Int
{
	case None = 0
	case Zoom = 1
	case Custom = 2
}

let DefaultSubviewsGap: CGFloat = 30.0
let MaxSpareViews = 1

class LBPhotoGalleryView: UIView, LBPhotoGalleryDelegate
{
	var mainScrollView: UIScrollView!
	
	var mainScrollIndicatorView: UIImageView!
	
	var reusableViews = [LBPhotoContainerView]()
	var dataSourceNumOfViews: Int = 0
	var initialIndex: Int = 0
	var currentPage: Int = 0
	
	@IBOutlet var delegate: LBPhotoGalleryDelegate?
	@IBOutlet var dataSource: LBPhotoGalleryDataSource?
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		
		self.autoresizingMask = .FlexibleTopMargin | .FlexibleLeftMargin | .FlexibleWidth | .FlexibleHeight
		
		self.initMainScrollView()
	}

	required init(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		
		self.autoresizingMask = .FlexibleTopMargin | .FlexibleLeftMargin | .FlexibleWidth | .FlexibleHeight;
		
		self.initMainScrollView()
	}
	
	override func awakeFromNib()
	{
		super.awakeFromNib()
		self.initMainScrollView()
		
	}
	
	override func layoutSubviews()
	{
		super.layoutSubviews()
		
		self.setupMainScrollView()
	}
	
	// MARK: - Public methods
	var galleryMode: LBPhotoGalleryMode = .ImageLocal
	{
		didSet {
			self.layoutSubviews()
		}
	}

	var captionStyle: LBPhotoCaptionStyle = .PlainText
	{
		didSet {
			self.layoutSubviews()
		}
	}
	
	var peakSubView: Bool = false
	{
		didSet {
			mainScrollView.clipsToBounds = peakSubView
		}
	}
	
	var showScrollIndicators: Bool = false
	{
		didSet {
			if showScrollIndicators {
				self.setupScrollIndicator()
			}
		}
	}
	
	var verticalGallery: Bool = false
	{
		didSet {
			updateSubviewsGap()
			currentPage = initialIndex
			
			self.scrollToPage(currentPage, animated:false)
		}
	}
	
	var subviewGap: CGFloat = 0
	{
		didSet {
			updateSubviewsGap()
		}
	}
	
	func updateSubviewsGap()
	{
		var frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)
		
		if verticalGallery {
			frame.size.height += subviewGap
		}
		else {
			frame.size.width += subviewGap
		}
		
		mainScrollView.frame = frame
		mainScrollView.contentSize = frame.size
	}
	
	func setInitialIndex(index: Int, animated: Bool)
	{
		initialIndex = index
		currentPage = index
		
		self.scrollToPage(currentPage, animated:animated)
	}
	
	func scrollToPage(page: Int, animated: Bool) -> Bool
	{
		if page < 0 || page >= dataSourceNumOfViews {
			return false
		}
		
		currentPage = page;
		self.populateSubviews()
		
		var contentOffset = mainScrollView.contentOffset
		
		if verticalGallery {
			contentOffset.y = CGFloat(currentPage) * mainScrollView.frame.size.height
		}
		else {
			contentOffset.x = CGFloat(currentPage) * mainScrollView.frame.size.width
		}
		
		mainScrollView.setContentOffset(contentOffset, animated:animated)
		
		return true
	}
	
	func scrollToBesidePage(delta: Int, animated: Bool) -> Bool
	{
		return self.scrollToPage(currentPage + delta, animated: animated)
	}

	func getCurrentView() -> LBPhotoContainerView?
	{
		for view in mainScrollView.subviews {
			if view is LBPhotoContainerView && view.tag == currentPage {
				return (view as LBPhotoContainerView)
			}
		}
		
		return nil
	}
	
	
	// MARK: - UIScrollViewDelegate
	func scrollViewDidScroll(scrollView: UIScrollView)
	{
		var newPage: CGFloat
		var scrollIndicatorMoveSpace: CGFloat
		
		var frame = mainScrollIndicatorView.frame
		
		if verticalGallery {
			newPage = scrollView.contentOffset.y / scrollView.frame.size.height
			if dataSourceNumOfViews == 1 {
				scrollIndicatorMoveSpace = 0
			}
			else {
				scrollIndicatorMoveSpace = (self.frame.size.height - mainScrollIndicatorView.frame.size.height) / CGFloat(dataSourceNumOfViews - 1)
			}
			frame.origin.y = newPage * scrollIndicatorMoveSpace
		} else {
			newPage = scrollView.contentOffset.x / scrollView.frame.size.width;
			if dataSourceNumOfViews == 1 {
				scrollIndicatorMoveSpace = 0
			}
			else {
				scrollIndicatorMoveSpace = (self.frame.size.width - mainScrollIndicatorView.frame.size.width) / CGFloat(dataSourceNumOfViews - 1)
			}
			frame.origin.x = newPage*scrollIndicatorMoveSpace;
		}
		
		mainScrollIndicatorView.frame = frame
		
		if Int(newPage) != currentPage {
			currentPage = Int(newPage)
			self.populateSubviews()
			
			for subView in reusableViews {
				if subView.tag != Int(newPage) {
					subView.resetZoom()
				}
			}
		}
		
		// HACK? Was delegate!!
		self.scrollViewDidScroll(scrollView)
	}
	
	func scrollViewWillBeginDragging(scrollView: UIScrollView)
	{
		mainScrollIndicatorView.tag = 1
		UIView.animateWithDuration(0.3, { () -> Void in
			self.mainScrollIndicatorView.alpha = 1
		})

		// HACK? Was delegate!!
		self.scrollViewWillBeginDragging(scrollView)
	}
	
	func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool)
	{
		if !decelerate {
			self.scrollViewDidEndDecelerating(scrollView)
		}
		
		// HACK? Was delegate!!
		self.scrollViewDidEndDragging(scrollView, willDecelerate:decelerate)
	}
	
	func scrollViewDidEndDecelerating(scrollView: UIScrollView)
	{
		self.delegate?.photoGallery?(self, didMoveToIndex: currentPage)
		
		mainScrollIndicatorView.tag = 0
		
		weak var weakMainScrollIndicatorView = mainScrollIndicatorView
		
		var popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
		dispatch_after(popTime, dispatch_get_main_queue(), { () -> Void in
			if let uIndView = weakMainScrollIndicatorView {
				if (uIndView.tag == 0) {
					UIView.animateWithDuration(0.5, animations: { () -> Void in
						uIndView.alpha = 0
					})
				}
			}
		})
	}
	
	// MARK: - protected methods (if only :( )
	
	func initMainScrollView()
	{
		var frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
		
		if verticalGallery {
			frame.size.height += subviewGap
		}
		else {
			frame.size.width += subviewGap
		}
		
		mainScrollView.removeFromSuperview()
		
		mainScrollView = UIScrollView(frame:frame)
		mainScrollView.autoresizingMask = self.autoresizingMask
		mainScrollView.backgroundColor = UIColor.clearColor()
		mainScrollView.clipsToBounds = false
		mainScrollView.contentSize = frame.size
		mainScrollView.delegate = self
		mainScrollView.pagingEnabled = true
		mainScrollView.showsHorizontalScrollIndicator = false
		mainScrollView.showsVerticalScrollIndicator = false
		
		self.addSubview(mainScrollView)
		
		reusableViews.removeAll(keepCapacity: false)
		currentPage = 0;
	}
	
	func setupMainScrollView()
	{
		assert(dataSource != nil, "Missing dataSource")
		assert(dataSource!.respondsToSelector("numberOfViewsInPhotoGallery:"),
			"Missing dataSource method numberOfViewsInPhotoGallery:")
		
		switch galleryMode {
		case .ImageLocal:
			assert(dataSource!.respondsToSelector("photoGallery:localImageAtIndex:"),
				"LBPhotoGalleryMode.ImageLocal mode missing dataSource method photoGallery:localImageAtIndex:")
		case .ImageRemote:
			assert(dataSource!.respondsToSelector("photoGallery:remoteImageURLAtIndex:"),
				"LBPhotoGalleryMode.ImageRemote mode missing dataSource method photoGallery:remoteImageURLAtIndex:")
		case .CustomView:
			assert(dataSource!.respondsToSelector("photoGallery:customViewAtIndex:"),
				"LBPhotoGalleryMode.CustomView mode missing dataSource method photoGallery:viewAtIndex:")
		}
		
		self.initMainScrollView()
		
		dataSourceNumOfViews = dataSource!.numberOfViewsInPhotoGallery(self)
		
		if currentPage == 0 && initialIndex != 0 {
			currentPage = initialIndex
			initialIndex = 0
		}
		
		var tmpCurrentPage = currentPage
		
		self.updateSubviewsGap()
		
		var contentSize = mainScrollView.contentSize
		
		if verticalGallery {
			contentSize.height = mainScrollView.frame.size.height * CGFloat(dataSourceNumOfViews)
		}
		else {
			contentSize.width = mainScrollView.frame.size.width * CGFloat(dataSourceNumOfViews)
		}
		
		mainScrollView.contentSize = contentSize;
		
		for view in mainScrollView.subviews {
			if let uView = view as? LBPhotoContainerView {
				view.removeFromSuperview()
			}
		}
		
		reusableViews.removeAll(keepCapacity: false)
		
		self.scrollToPage(tmpCurrentPage, animated:false)
		self.setupScrollIndicator()
	}
	
	func reusableViewsContainViewAtIndex(index: Int) -> Bool
	{
		for view in reusableViews {
			if view.tag == index {
				return true
			}
		}
		
		return false
	}
	
	func populateSubviews()
	{
		for var i = reusableViews.count; i >= 0; i-- {
			var view = reusableViews[i]
			if view.tag < currentPage - MaxSpareViews || view.tag > currentPage + MaxSpareViews {
				view.removeFromSuperview()
				reusableViews.removeAtIndex(i)
			}
		}
		
		for var index = -MaxSpareViews; index <= MaxSpareViews; index++ {
			var assertIndex = currentPage + index
			if assertIndex < 0 || assertIndex >= dataSourceNumOfViews || self.reusableViewsContainViewAtIndex(assertIndex) {
				continue
			}
			
			var frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)
			
			if verticalGallery {
				frame.origin.y = CGFloat(assertIndex) * mainScrollView.frame.size.height
			}
			else {
				frame.origin.x = CGFloat(assertIndex) * mainScrollView.frame.size.width
			}
			
			if let subView = self.viewToBeAddedWithFrame(frame, atIndex:currentPage + index) {
				subView.resetZoom()
				mainScrollView.addSubview(subView)
				reusableViews.append(subView)
			}
		}
	}
	
	func viewToBeAddedWithFrame(frame: CGRect, atIndex index:Int) -> LBPhotoContainerView?
	{
		var galleryItem: AnyObject? = nil
		
		switch galleryMode {
		case .ImageLocal:
			galleryItem = dataSource!.photoGallery!(self, localImageAtIndex:index)
		case .ImageRemote:
			galleryItem = dataSource!.photoGallery!(self, remoteImageURLAtIndex:index)
		case .CustomView:
			galleryItem = dataSource!.photoGallery!(self, customViewAtIndex:index)
		}
		
		if galleryItem == nil {
			return nil
		}
		
		var subView = LBPhotoContainerView(frame: frame, galleryMode: galleryMode, item: galleryItem!)
		subView.tag = index
		subView.delegate = self
		subView.gallery = self
		
		var captionItem:AnyObject? = nil
		
		switch captionStyle {
		case .PlainText:
			if dataSource!.respondsToSelector("photoGallery:plainTextCaptionAtIndex:") {
				captionItem = dataSource!.photoGallery!(self, plainTextCaptionAtIndex:index)
			}
		case .AttributedText:
			if dataSource!.respondsToSelector("photoGallery:attributedTextCaptionAtIndex:") {
				captionItem = dataSource!.photoGallery!(self, attributedTextCaptionAtIndex:index)
			}
		case .CustomView:
			if dataSource!.respondsToSelector("photoGallery:customViewAtIndex:") {
				captionItem = dataSource!.photoGallery!(self, customViewCaptionAtIndex:index)
			}
		}
		
		if captionItem != nil {
			subView.setCaptionWithStyle(captionStyle, forItem:captionItem!)
		}
		
		return subView
	}
	
	func setupScrollIndicator()
	{
		mainScrollIndicatorView.removeFromSuperview()
		
		if showScrollIndicators {
			var scrollIndicatorLength: CGFloat = 0.0
			
			if verticalGallery {
				scrollIndicatorLength = self.frame.size.height / CGFloat(dataSourceNumOfViews)
			}
			else {
				scrollIndicatorLength = self.frame.size.width / CGFloat(dataSourceNumOfViews)
			}
			
			var scrollIndicator = self.scrollIndicatorForDirection(verticalGallery, andLength:scrollIndicatorLength)
			
			mainScrollIndicatorView = UIImageView(image: scrollIndicator)
			
			var frame = mainScrollIndicatorView.frame
			
			if verticalGallery {
				frame.origin.x = self.frame.size.width - frame.size.width
				frame.origin.y = 0
			}
			else {
				frame.origin.x = 0
				frame.origin.y = self.frame.size.height-frame.size.height
			}
			
			mainScrollIndicatorView.frame = frame
			mainScrollIndicatorView.alpha = 0
			self.addSubview(mainScrollIndicatorView)
		}
	}
	
	func scrollIndicatorForDirection(vertical: Bool, andLength length: CGFloat) -> UIImage
	{
		var radius: CGFloat = 3.5
		var ratio: CGFloat = 1.5 * length / radius
		
		if ratio < 2.5 {
			ratio = 2.5
		}
		
		var size = CGSize(width: radius * 2.0 * (vertical ? 1 : ratio), height: radius * 2.0 * (vertical ? ratio : 1))
		var lineWidth: CGFloat = 0.5
		
		UIGraphicsBeginImageContext(size)
		var context = UIGraphicsGetCurrentContext()
		CGContextSetLineWidth(context, lineWidth)
		CGContextSetAlpha(context, 0.8)
		
		CGContextBeginPath(context)
		CGContextAddArc(context, radius, radius, radius - lineWidth,
			CGFloat(-M_PI_2 - (vertical ? M_PI_2 : 0.0)), CGFloat(M_PI_2 - (vertical ? M_PI_2 : 0.0)), vertical ? 0 : 1)
		CGContextAddArc(context, size.width - radius, size.height - radius, radius - lineWidth,
			CGFloat(M_PI_2 - (vertical ? M_PI_2 : 0.0)), CGFloat(-M_PI_2 - (vertical ? M_PI_2 : 0.0)), vertical ? 0 : 1)
		CGContextClosePath(context)
		
		UIColor.grayColor().set()
		CGContextStrokePath(context)
		var scrollIndicator = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return scrollIndicator
	}
}

// MARK: - LBPhotoGalleryDataSource

@objc protocol LBPhotoGalleryDataSource: NSObjectProtocol
{
	func numberOfViewsInPhotoGallery(gallery: LBPhotoGalleryView) -> Int
	
	optional func photoGallery(gallery: LBPhotoGalleryView, localImageAtIndex: Int) -> UIImage?
	optional func photoGallery(gallery: LBPhotoGalleryView, remoteImageURLAtIndex: Int) -> NSURL?
	optional func photoGallery(gallery: LBPhotoGalleryView, customViewAtIndex: Int) -> UIView?
	
	optional func photoGallery(gallery: LBPhotoGalleryView, plainTextCaptionAtIndex: Int) -> NSString?
	optional func photoGallery(gallery: LBPhotoGalleryView, attributedTextCaptionAtIndex: Int) -> NSAttributedString?
	optional func photoGallery(gallery: LBPhotoGalleryView, customViewCaptionAtIndex: Int) -> UIView?
	
	optional func customTopViewForGalleryViewController(galleryViewController: LBPhotoGalleryViewController) -> UIView?
	optional func customBottomViewForGalleryViewController(galleryViewController: LBPhotoGalleryViewController) -> UIView?
}

// MARK: - LBPhotoGalleryDelegate

@objc protocol LBPhotoGalleryDelegate: UIScrollViewDelegate
{
	optional func photoGallery(gallery: LBPhotoGalleryView, didTapAtIndex: Int)
	optional func photoGallery(gallery: LBPhotoGalleryView, didDoubleTapAtIndex: Int)
	optional func photoGallery(gallery: LBPhotoGalleryView, didMoveToIndex: Int)
	optional func photoGallery(gallery: LBPhotoGalleryView, doubleTapHandlerAtIndex: Int) -> Int
}

// MARK: - LBPhotoItemDelegate

@objc protocol LBPhotoItemDelegate
{
	optional func photoItemDidSingleTapAtIndex(index: Int)
	optional func photoItemDidDoubleTapAtIndex(index: Int)
}
