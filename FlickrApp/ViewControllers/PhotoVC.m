//
//  PhotoVC.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "PhotoVC.h"
#import "Photo.h"
#import "NetworkManager.h"

@interface PhotoVC ()
{
	BOOL _needRefresh;
}

@property (nonatomic, strong) UIScrollView* scrollView;
@property (nonatomic, strong) PhotoImageView* imageView;
@property (nonatomic, strong) UILabel* authorLabel;
@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UIView* bottomPanel;

@end

@implementation PhotoVC

static const CGFloat kBottomPanelHeight = 44.f;

- (void)loadView
{
	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.view.backgroundColor = [UIColor blackColor];
	self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
	_scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_scrollView.showsHorizontalScrollIndicator = NO;
	_scrollView.showsVerticalScrollIndicator = NO;
	_scrollView.minimumZoomScale = 0.25f;
	_scrollView.maximumZoomScale = 1.f;
	_scrollView.bouncesZoom = YES;
	_scrollView.delegate = self;
	[self.view addSubview:_scrollView];
	
	self.imageView = [[PhotoImageView alloc] initWithFrame:self.scrollView.bounds];
	_imageView.useMemoryCache = NO;
	_imageView.userInteractionEnabled = NO;
	_imageView.delegate = self;
	[self.scrollView addSubview:_imageView];
	
	self.bottomPanel = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - kBottomPanelHeight, CGRectGetWidth(self.view.bounds), kBottomPanelHeight)];
	_bottomPanel.backgroundColor = [UIColor whiteColor];
	_bottomPanel.userInteractionEnabled = NO;
	_bottomPanel.alpha = 0.4f;
	_bottomPanel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;	
	[self.view addSubview:_bottomPanel];
	
	self.authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_bottomPanel.bounds), kBottomPanelHeight/2)];
	_authorLabel.textAlignment = NSTextAlignmentCenter;
	_authorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[_bottomPanel addSubview:_authorLabel];
	self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kBottomPanelHeight/2, CGRectGetWidth(_bottomPanel.bounds), kBottomPanelHeight/2)];
	_titleLabel.textAlignment = NSTextAlignmentCenter;
	_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[_bottomPanel addSubview:_titleLabel];
	
	_needRefresh = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (_needRefresh) {
		_needRefresh = NO;
		[self refresh];
	}
}

- (void)refresh
{
	_imageView.image = nil;
	[self resetScale];
		[_imageView setImageWithURL:[[NetworkManager sharedManager] urlForImageInfo:_itemInfo]];
	
	self.navigationItem.title = _titleLabel.text = _itemInfo.title;
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	_needRefresh = YES;
}

- (void)resetScale
{
	_scrollView.zoomScale = 1.f;
	_scrollView.contentSize = CGSizeZero;
	_scrollView.contentOffset = CGPointMake(0, -_scrollView.contentInset.top);
	_imageView.frame = _scrollView.bounds;
}

#pragma mark - autorotation

- (BOOL)shouldAutorotate
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

#pragma mark - image view delegate

- (void)imageViewDidLoadImage:(PhotoImageView*)imageView
{
	_scrollView.contentSize = imageView.bounds.size;
	_scrollView.zoomScale = 0.5f * (_scrollView.minimumZoomScale + _scrollView.maximumZoomScale);
	_scrollView.contentOffset = CGPointMake(0, -_scrollView.contentInset.top);
}

- (void)imageViewFailedToLoadImage:(PhotoImageView*)imageView
{
	[[[UIAlertView alloc] initWithTitle:nil message:@"Failed to load image" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - scroll view delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return _imageView;
}

@end
