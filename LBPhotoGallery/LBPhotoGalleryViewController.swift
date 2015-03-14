//
//  LBPhotoGalleryViewController.swift
//  LBPhotoGalleryExample
//
//  Created by Jan Kosa on 06/03/15.
//  Copyright (c) 2015 Jan Kosa. All rights reserved.
//

import UIKit

class LBPhotoGalleryViewController: UIViewController, LBPhotoGalleryDelegate, LBPhotoGalleryDataSource
{
	var photoGallery: LBPhotoGalleryView!
	
	var topView: UIView!
	var bottomView: UIView?
	
	var statusBarHidden: Bool = false
	var showStatusBar: Bool = false
	var controlViewHidden: Bool = true
	
	func commonInit()
	{
		self.view.frame = UIScreen.mainScreen().bounds
		self.view.backgroundColor = UIColor.blackColor()
		self.view.autoresizingMask = .FlexibleTopMargin | .FlexibleLeftMargin | .FlexibleWidth | .FlexibleHeight
		
		photoGallery = LBPhotoGalleryView(frame: UIScreen.mainScreen().bounds)
		photoGallery.dataSource = self
		photoGallery.delegate = self
		
		self.view.addSubview(photoGallery)
		
		statusBarHidden = UIApplication.sharedApplication().statusBarHidden
		controlViewHidden = false
		self.setupTopBar()
		self.setupBottomBar()
	}
	
	override init()
	{
		super.init(nibName: nil, bundle: nil)
		
		commonInit()
	}

	required init(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		
		commonInit()
	}
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
	{
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		
		commonInit()
	}
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		if !statusBarHidden && !showStatusBar {
			UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Slide)
			self.view.frame = UIScreen.mainScreen().bounds
			
			if self.navigationController != nil {
				self.navigationController!.setNavigationBarHidden(true, animated:true)
			}
		}
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)
		
		if !statusBarHidden {
			UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation:.Slide)
			
			if self.navigationController != nil {
				self.navigationController!.setNavigationBarHidden(false, animated:true)
			}
		}
	}
	
	@IBOutlet var dataSource: LBPhotoGalleryDataSource?
	{
		didSet {
			if dataSource == nil {
				photoGallery.dataSource = self
			}
			else {
				photoGallery.dataSource = dataSource
			}
			
			self.setupTopBar()
			self.setupBottomBar()
		}
	}
	
	// MARK: - getters/setters
	
	var galleryMode: LBPhotoGalleryMode!
	{
		didSet {
			photoGallery.galleryMode = galleryMode
		}
	}
	
	var captionStyle: LBPhotoCaptionStyle = .PlainText
	{
		didSet {
			photoGallery.captionStyle = captionStyle
		}
	}
	
	var peakSubview: Bool = false
	{
		didSet {
			photoGallery.peakSubView = peakSubview
		}
	}
	
	var verticalGallery: Bool = false
	{
		didSet {
			photoGallery.verticalGallery = verticalGallery
		}
	}
	
	var subviewGap: CGFloat = 0
	{
		didSet {
			photoGallery.subviewGap = subviewGap
		}
	}
	
	var initialIndex: Int = 0
	{
		didSet {
			photoGallery.initialIndex = initialIndex
		}
	}
	
	// MARK: - LBPhotoGalleryDataSource
	
	func numberOfViewsInPhotoGallery(gallery: LBPhotoGalleryView) -> Int
	{
		return 0
	}
	
	func photoGallery(gallery: LBPhotoGalleryView, localImageAtIndex: Int) -> UIImage?
	{
		return nil
	}
	
	func photoGallery(gallery: LBPhotoGalleryView, remoteImageURLAtIndex: Int) -> NSURL?
	{
		return nil
	}
	
	func photoGallery(gallery: LBPhotoGalleryView, customViewAtIndex: Int) -> UIView?
	{
		return nil
	}
	
	// MARK: - LBPhotoGalleryDelegate
	
	func photoGallery(gallery: LBPhotoGalleryView, didTapAtIndex: Int)
	{
		controlViewHidden = !controlViewHidden;
		
		UIView.animateWithDuration(0.3, animations: { () -> Void in
			var frame = self.topView.frame
			frame.origin.y = (self.controlViewHidden ? -1 : 0) * frame.size.height
			self.topView.frame = frame
			self.topView.alpha = self.controlViewHidden ? 0 : 1
			
			if let bottom = self.bottomView {
				var frame = bottom.frame
				
				if self.controlViewHidden {
					frame.origin.y += frame.size.height
				}
				else {
					frame.origin.y -= frame.size.height
				}
				
				bottom.frame = frame
				bottom.alpha = self.controlViewHidden ? 0 : 1
			}
		})
	}
	
	// MARK: - protected methods
	
	func setupTopBar()
	{
		if topView != nil {
			topView.removeFromSuperview()
		}
		
		if dataSource != nil && dataSource!.respondsToSelector("customTopViewForGalleryViewController:") {
			topView = dataSource!.customTopViewForGalleryViewController!(self)
			topView!.frame = CGRectMake(0, 0, topView!.frame.size.width, topView!.frame.size.height)
			topView!.autoresizingMask = .FlexibleLeftMargin | .FlexibleWidth
			self.view.addSubview(topView!)
			return
		}
		
		var topViewBar = UIToolbar(frame: CGRectMake(0, 0, self.view.frame.size.width, 44))
		topViewBar.barStyle = .Black
		topViewBar.autoresizingMask = .FlexibleWidth
		
		var btnDone = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "btnDonePressed")
		topViewBar.setItems([btnDone], animated:true)
		
		topView = UIView(frame: topViewBar.frame)
		topView.autoresizingMask = .FlexibleWidth;
		topView.addSubview(topViewBar)
		self.view.addSubview(topView)
	}
	
	func setupBottomBar()
	{
		if let bottom = bottomView {
			bottom.removeFromSuperview()
		}
		bottomView = nil
		
		if dataSource != nil && dataSource!.respondsToSelector("customBottomViewForGalleryViewController:") {
			if let bottom = dataSource!.customBottomViewForGalleryViewController!(self) {
				bottomView = bottom
				bottomView!.frame = CGRectMake(0, self.view.frame.size.height - bottomView!.frame.size.height, bottomView!.frame.size.width, bottomView!.frame.size.height)
				self.view.addSubview(bottomView!)
			}
			return
		}
		
		// TODO: add bool property telling us if we even want bottom bar
		var bottomViewBar = UIToolbar(frame: CGRectMake(0, 0, self.view.frame.size.width, 44))
		bottomViewBar.barStyle = .Black
		bottomViewBar.autoresizingMask = .FlexibleWidth
		
		var btnPrev = UIBarButtonItem(title: "Prev", style: .Plain, target: self, action: "btnPrevPressed")
		var flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
		var btnNext = UIBarButtonItem(title: "Next", style: .Plain, target: self, action: "btnNextPressed")
		bottomViewBar.setItems([btnPrev, flexSpace, btnNext], animated:true)
		
		bottomView = UIView(frame: CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44))
		bottomView!.autoresizingMask = .FlexibleLeftMargin | .FlexibleTopMargin | .FlexibleRightMargin | .FlexibleWidth
		bottomView!.addSubview(bottomViewBar)
		self.view.addSubview(bottomView!)
	}
	
	func btnDonePressed()
	{
		if let navc = self.navigationController {
			navc.popViewControllerAnimated(true)
		}
		else {
			self.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	func btnPrevPressed()
	{
		photoGallery.scrollToBesidePage(-1, animated: true)
	}
	
	func btnNextPressed()
	{
		photoGallery.scrollToBesidePage(1, animated: true)
	}
}
