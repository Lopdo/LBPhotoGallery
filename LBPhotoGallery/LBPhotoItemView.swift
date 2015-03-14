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
	
	// MARK: - UIScrollViewDelegate methods
	func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
	{
		return mainImageView
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
						
						var widthScale = image.size.width / selfW.photoItemView.frame.size.width
						var heightScale = image.size.height / selfW.photoItemView.frame.size.height
						selfW.photoItemView.maximumZoomScale = min(widthScale, heightScale) * MaxZoomingScale
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

let captionPadding: CGFloat = 8.0

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
		var captionFont = UIFont.systemFontOfSize(14)
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