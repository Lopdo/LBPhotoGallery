//
//  LBPhotoItemView.swift
//  PhotoGallery
//
//  Created by Jan Kosa on 06/03/15.
//  Copyright (c) 2015 Jan Kosa. All rights reserved.
//

import UIKit

let MaxZoomingScale: CGFloat = 2.0

class LBPhotoContainerView: UIView
{
	var photoItemView: LBPhotoItemView!
	var photoCaptionView: LBPhotoCaptionView?
	
	required init(frame: CGRect, galleryMode: LBPhotoGalleryMode, item: AnyObject)
	{
		var displayFrame = CGRect(origin: CGPoint(x: 0, y: 0), size: frame.size)

		super.init(frame: frame)

		switch (galleryMode) {
			case .ImageLocal:
				photoItemView = LBPhotoItemView(frame: displayFrame, localImage: item as UIImage)
			case .ImageRemote:
				photoItemView = LBPhotoItemView(frame: displayFrame, remoteURL: item as NSURL)
			case .CustomView:
				photoItemView = LBPhotoItemView(frame: displayFrame, customView: item as UIView)
			
		}

		self.addSubview(photoItemView)
		self.tag = 1
	}

	required init(coder aDecoder: NSCoder)
	{
	    super.init(coder: aDecoder)
	}

	override var tag: Int
	{
		didSet {
			photoItemView.tag = tag
		}
	}
	
	var gallery: LBPhotoGalleryView?
	{
		didSet {
			photoItemView.gallery = gallery
		}
	}
	
	var galleryDelegate: LBPhotoGalleryDelegate?
	{
		didSet {
			photoItemView.galleryDelegate = galleryDelegate
		}
	}
	
	func setCaptionWithStyle(style: LBPhotoCaptionStyle, forItem item: AnyObject)
	{
		if let view = photoCaptionView {
			view.removeFromSuperview()
		}
		
		switch (style) {
		case .PlainText:
			photoCaptionView = LBPhotoCaptionView(frame: self.frame, plainText: item as NSString)
		case .AttributedText:
			photoCaptionView = LBPhotoCaptionView(frame: self.frame, attributedText: item as NSAttributedString)
		case .CustomView:
			photoCaptionView = LBPhotoCaptionView(frame: self.frame, customView: item as UIView)
		}
		
		self.addSubview(photoCaptionView!)
	}
	
	func setCaptionHidden(hidden: Bool, animated: Bool)
	{
		if let view = photoCaptionView {
			view.setCaptionHidden(hidden, animated: animated)
		}
	}
	
	func resetZoom()
	{
		photoItemView.resetZoom()
	}

}

class LBPhotoItemView: UIScrollView, UIScrollViewDelegate
{
	var mainImageView: UIView?
	var gallery: LBPhotoGalleryView?
	var galleryDelegate: LBPhotoGalleryDelegate?
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		
		self.contentSize = self.frame.size;
		self.backgroundColor = UIColor.clearColor()
		self.clipsToBounds = true
		self.delegate = self
		self.minimumZoomScale = 1
		self.userInteractionEnabled = true
		self.decelerationRate = UIScrollViewDecelerationRateFast
		self.bounces = true
		
		var singleTapGesture = UITapGestureRecognizer(target: self, action: "tapGestureRecognizer:")
		singleTapGesture.numberOfTapsRequired = 1
		singleTapGesture.numberOfTouchesRequired = 1
		self.addGestureRecognizer(singleTapGesture)
		
		var doubleTapGesture = UITapGestureRecognizer(target: self, action: "tapGestureRecognizer:")
		doubleTapGesture.numberOfTapsRequired = 2
		doubleTapGesture.numberOfTouchesRequired = 1
		self.addGestureRecognizer(doubleTapGesture)
		
		singleTapGesture.requireGestureRecognizerToFail(doubleTapGesture)
	}
	
	convenience init(frame: CGRect, localImage:UIImage)
	{
		self.init(frame: frame)
		
		
		var imageView = UIImageView(frame: frame)
		imageView.backgroundColor = UIColor.clearColor()
		imageView.contentMode = .ScaleAspectFit
		imageView.autoresizingMask = .FlexibleTopMargin | .FlexibleLeftMargin | .FlexibleWidth | .FlexibleHeight
		imageView.image = localImage
		
		mainImageView = imageView;
		self.addSubview(imageView)
		
		var widthScale = localImage.size.width / self.frame.size.width
		var heightScale = localImage.size.height / self.frame.size.height
		self.maximumZoomScale = min(widthScale, heightScale) * MaxZoomingScale;
	}
	
	convenience init(frame: CGRect, remoteURL: NSURL)
	{
		self.init(frame: frame)
		
		var remotePhoto = LBRemotePhotoItem(frame: frame, remoteURL:remoteURL)
		remotePhoto.photoItemView = self
		mainImageView = remotePhoto
		self.addSubview(remotePhoto)
	}
	
	convenience init(frame: CGRect, customView: UIView)
	{
		self.init(frame: frame)
		
		self.addSubview(customView)
	}

	required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews()
	{
		super.layoutSubviews()
		
		// center the image as it becomes smaller than the size of the screen
		if let uMainImageView = mainImageView {
			var boundsSize = self.bounds.size
			var frameToCenter = uMainImageView.frame
			
			// center horizontally
			if frameToCenter.size.width < boundsSize.width {
				frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
			}
			else {
				frameToCenter.origin.x = 0
			}
			
			// center vertically
			if frameToCenter.size.height < boundsSize.height {
				frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
			}
			else {
				frameToCenter.origin.y = 0
			}
			
			uMainImageView.frame = frameToCenter
		}
	}
	
	/*deinit
	{
		if let uMainImageView = mainImageView as? LBRemotePhotoItem {
			uMainImageView.photoItemView = nil
		}
	}*/
	
	func tapGestureRecognizer(tapGesture: UITapGestureRecognizer)
	{
		if let uDelegate = galleryDelegate {
			if (tapGesture.numberOfTapsRequired == 1) {
				if uDelegate.respondsToSelector("photoGallery:didTapAtIndex:") {
					uDelegate.photoGallery!(gallery!, didTapAtIndex: self.tag)
				}
				return
			}
			
			if !uDelegate.respondsToSelector("photoGallery:doubleTapHandlerAtIndex:") {
				self.zoomFromLocation(tapGesture.locationInView(self))
				return
			}
			
			switch LBPhotoGalleryDoubleTapHandler(rawValue: uDelegate.photoGallery!(gallery!, doubleTapHandlerAtIndex:self.tag))! {
			case .Zoom:
				self.zoomFromLocation(tapGesture.locationInView(self))
			case .Custom:
				if uDelegate.respondsToSelector("photoGallery:didDoubleTapAtIndex:") {
					uDelegate.photoGallery!(gallery!, didDoubleTapAtIndex:self.tag)
				}
			default:    // .None
				break;
			}
		}
	}
	
	func zoomFromLocation(zoomLocation: CGPoint)
	{
		var scrollViewSize = self.frame.size
		
		var zoomScale = (fabs(self.zoomScale - self.maximumZoomScale) <= 0.001) ?
			self.minimumZoomScale : self.maximumZoomScale
		
		var width = scrollViewSize.width / zoomScale
		var height = scrollViewSize.height / zoomScale
		var x = zoomLocation.x - (width / 2)
		var y = zoomLocation.y - (height / 2)
		
		self.zoomToRect(CGRectMake(x, y, width, height), animated:true)
	}
	
	func resetZoom()
	{
		if (fabs(self.zoomScale - self.minimumZoomScale) > 0.001) {
			var scrollViewSize = self.frame.size
			
			var zoomScale = self.minimumZoomScale
			
			var width = scrollViewSize.width / zoomScale
			var height = scrollViewSize.height / zoomScale
			
			self.zoomToRect(CGRectMake(0, 0, width, height), animated:false)
		}
	}
	
	func setMaxMinZoomScalesForCurrentBounds()
	{
		if let uMainImageView = mainImageView {
			var boundsSize = self.bounds.size
			var imageSize = uMainImageView.bounds.size
			
			// calculate min/max zoomscale
			var minScale = boundsSize.width / imageSize.width
			
			// on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
			// maximum zoom scale to 0.5.
			//CGFloat maxScale = 1.0 / [[UIScreen mainScreen] scale];
			
			// we don't want to behave any different on retina displays
			var maxScale: CGFloat = 1.0
			
			// don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
			if minScale > maxScale {
				minScale = maxScale
			}
			
			self.maximumZoomScale = maxScale
			self.minimumZoomScale = minScale
		}
	}

	
	// MARK: - UIScrollViewDelegate methods
	func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
	{
		return mainImageView
	}
	
	// MARK: - Methods called during rotation to preserve the zoomScale and the visible portion of the image
	
	// returns the center point, in image coordinate space, to try to restore after rotation.
	func pointToCenterAfterRotation() -> CGPoint
	{
		var boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
		return self.convertPoint(boundsCenter, toView:mainImageView)
	}
	
	// returns the zoom scale to attempt to restore after rotation.
	func scaleToRestoreAfterRotation() -> CGFloat
	{
		var contentScale = self.zoomScale
	
		// If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
		// allowable scale when the scale is restored.
		if contentScale <= self.minimumZoomScale + CGFloat(FLT_EPSILON) {
			contentScale = 0
		}
		
		return contentScale
	}
	
	func maximumContentOffset() -> CGPoint
	{
		var contentSize = self.contentSize
		var boundsSize = self.bounds.size
		return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height)
	}
	
	func minimumContentOffset() -> CGPoint
	{
		return CGPointZero
	}
	
	// Adjusts content offset and scale to try to preserve the old zoomscale and center.
	func restoreCenterPoint(oldCenter: CGPoint, scale oldScale: CGFloat)
	{
		self.setMaxMinZoomScalesForCurrentBounds()
	
		if let uMainImageView = mainImageView {
			// Step 1: restore zoom scale, first making sure it is within the allowable range.
			self.zoomScale = min(self.maximumZoomScale, max(self.minimumZoomScale, oldScale))
			
			// Step 2: restore center point, first making sure it is within the allowable range.
			
			// 2a: convert our desired center point back to our own coordinate space
			var boundsCenter = self.convertPoint(oldCenter, fromView:uMainImageView)
			// 2b: calculate the content offset that would yield that center point
			var offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
				boundsCenter.y - self.bounds.size.height / 2.0)
			// 2c: restore offset, adjusted to be within the allowable range
			var maxOffset = self.maximumContentOffset()
			var minOffset = self.minimumContentOffset()
			offset.x = max(minOffset.x, min(maxOffset.x, offset.x))
			offset.y = max(minOffset.y, min(maxOffset.y, offset.y))
			self.contentOffset = offset
		}
	}
}

class LBRemotePhotoItem: UIImageView
{
	var photoItemView: LBPhotoItemView!
	
	init(frame: CGRect, remoteURL: NSURL)
	{
		super.init(frame: frame)
		
		self.userInteractionEnabled = true
		self.backgroundColor = UIColor.clearColor()
		self.contentMode = .ScaleAspectFit;
		self.autoresizingMask = .FlexibleTopMargin | .FlexibleLeftMargin | .FlexibleWidth | .FlexibleHeight;
		
		var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
		activityIndicator.frame = frame
		activityIndicator.startAnimating()
		
		self.addSubview(activityIndicator)
		
		weak var weakSelf = self
		
		var delayInSeconds = 0.0
		var popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds * Double(NSEC_PER_SEC)))
		dispatch_after(popTime, dispatch_get_main_queue(), { () -> Void in
			if let selfW = weakSelf {
				selfW.sd_setImageWithURL(remoteURL, completed: { (image, error, cacheType, url) -> Void in
					if (error == nil && image != nil) {
						activityIndicator.removeFromSuperview()
						
						selfW.frame = CGRectMake(0, 0, image.size.width, image.size.height)
						selfW.photoItemView.contentSize = image.size
						
						selfW.photoItemView.setMaxMinZoomScalesForCurrentBounds()
						selfW.photoItemView.zoomScale = selfW.photoItemView.minimumZoomScale
						
						/*var widthScale = image.size.width / selfW.photoItemView.frame.size.width
						var heightScale = image.size.height / selfW.photoItemView.frame.size.height
						selfW.photoItemView.maximumZoomScale = min(widthScale, heightScale) * MaxZoomingScale
						selfW.frame.size.width = image.size.width
						selfW.frame.size.height = image.size.height
						selfW.center = selfW.photoItemView.center*/
					}
				})
			}
		})
	}

	required init(coder aDecoder: NSCoder)
	{
	    super.init(coder: aDecoder)
	}
}

let captionPadding: CGFloat = 12.0

class LBPhotoCaptionView: UIView
{
	init(frame: CGRect, plainText:NSString)
	{
		super.init(frame: frame)
		
		var captionLabel = self.captionLabelWithPlainText(plainText, orAttributedText:nil, fromFrame:frame)
		
		var captionFrame = CGRectMake(0, frame.size.height - captionLabel.frame.size.height - 2 * captionPadding,
			captionLabel.frame.size.width + 2 * captionPadding, captionLabel.frame.size.height + 2 * captionPadding)
		
		self.frame = captionFrame
		
		var backgroundView = UIView(frame: self.bounds)
		backgroundView.backgroundColor = UIColor.blackColor()
		backgroundView.alpha = 0.6
		
		self.backgroundColor = UIColor.clearColor()
		self.autoresizingMask = .FlexibleTopMargin | .FlexibleWidth
			
		self.addSubview(backgroundView)
		self.addSubview(captionLabel)
	}
	
	init(frame: CGRect, attributedText: NSAttributedString)
	{
		super.init(frame: frame)
		
		var captionLabel = self.captionLabelWithPlainText(nil, orAttributedText:attributedText, fromFrame:frame)
		
		var captionFrame = CGRectMake(0, frame.size.height - captionLabel.frame.size.height - 2 * captionPadding,
			captionLabel.frame.size.width + 2 * captionPadding, captionLabel.frame.size.height + 2 * captionPadding)
		
		self.frame = captionFrame
		
		var backgroundView = UIView(frame: self.bounds)
		backgroundView.backgroundColor = UIColor.blackColor()
		backgroundView.alpha = 0.6
		
		self.backgroundColor = UIColor.clearColor()
		self.autoresizingMask = .FlexibleTopMargin | .FlexibleWidth
		
		self.addSubview(backgroundView)
		self.addSubview(captionLabel)
	}
	
	init(frame: CGRect, customView: UIView)
	{
		var captionFrame = CGRectMake(0, frame.size.height-customView.frame.size.height,
			frame.size.width, customView.frame.size.height)
		
		super.init(frame: captionFrame)

		self.backgroundColor = UIColor.clearColor()
		self.autoresizingMask = .FlexibleTopMargin | .FlexibleWidth
			
		self.addSubview(customView)
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func captionLabelWithPlainText(plainText: NSString?, orAttributedText
		attributedText: NSAttributedString?, fromFrame frame: CGRect) -> UILabel
	{
		var captionFont = UIFont.systemFontOfSize(16)
		var captionSize = CGSizeZero
		
		if let pt = plainText {
			captionSize = pt.boundingRectWithSize(CGSizeMake(frame.size.width - 2 * captionPadding, CGFloat(MAXFLOAT)), options: .UsesLineFragmentOrigin,
				attributes: [NSFontAttributeName: captionFont], context: nil).size
		}
		if let at = attributedText {
			captionSize = at.size()
		}
		
		if (captionSize.height > frame.size.height/3) {
			captionSize.height = frame.size.height/3
		}
		
		var captionLabel = UILabel(frame: CGRectMake(captionPadding, captionPadding,
			frame.size.width - 2 * captionPadding, captionSize.height))
		captionLabel.backgroundColor = UIColor.clearColor()
		captionLabel.font = captionFont
		captionLabel.numberOfLines = 0;
		captionLabel.textColor = UIColor.whiteColor()
		
		if (plainText != nil) {
			captionLabel.text = plainText as? String
		}
		else if (attributedText != nil) {
			captionLabel.attributedText = attributedText
		}
		
		return captionLabel
	}

	func setCaptionHidden(hidden: Bool, animated: Bool)
	{
		if let superview = self.superview {
			var superViewFrame = superview.frame
			
			if (!animated) {
				var frame = self.frame
				frame.origin.y = superViewFrame.size.height - (hidden ? 0 : 1)*self.frame.size.height
				self.frame = frame
				self.alpha = (hidden ? 0 : 1)
			}
			else {
				UIView.animateWithDuration(0.5, animations: { () -> Void in
					var frame = self.frame
					frame.origin.y = superViewFrame.size.height - (hidden ? 0 : 1)*self.frame.size.height
					self.frame = frame
					self.alpha = (hidden ? 0 : 1)
				})
			}
		}
	}
}