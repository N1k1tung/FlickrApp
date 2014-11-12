//
//  ThumbsVC.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "ThumbsVC.h"
#import "YPRSSLoader.h"
#import "YPRSSItem.h"
#import "ThumbCell.h"
#import "PhotoVC.h"
#import "YPDataStorage.h"

@interface ThumbsVC ()
{
	PhotoVC* _photoVC;
}

@property (strong) NSArray* items;

@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, strong) UIRefreshControl* refreshControl;


@end

@implementation ThumbsVC

static NSString* const kCellID = @"collectionCell";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.collectionView registerClass:[YPThumbCell class] forCellWithReuseIdentifier:kCellID];
	self.navigationItem.title = @"Photos";
	if (!_activityIndicator) {
		self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		_activityIndicator.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
		_activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
	}
	[self.view addSubview:_activityIndicator];
	if (!_refreshControl) {
		self.refreshControl = [[UIRefreshControl alloc] init];
		[_refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
		_refreshControl.tintColor = [UIColor grayColor];
	}
	
	[self.collectionView addSubview:_refreshControl];
	self.collectionView.alwaysBounceVertical = YES;
	
	self.items = [[YPDataStorage sharedStorage] fetchItems];
	
	[self refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	_photoVC = nil;
}

- (void)refresh
{
	[_activityIndicator startAnimating];
	[_refreshControl beginRefreshing];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError* error = nil;
		NSDictionary* rss = [YPRSSLoader loadRSS:&error];
		if (rss) {
			NSArray* items = [YPRSSLoader itemsFromRSSDictionary:rss];
			if (items.count)
				self.items = items;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.collectionView reloadData];
				if (items.count)
					[[YPDataStorage sharedStorage] rewriteItems:items];
				else
					[[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Error while parsing RSS feed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
			});
		} else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Error while loading RSS feed, check your internet connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
			});
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			[_activityIndicator stopAnimating];
			[_refreshControl endRefreshing];
		});

	});
	
}

#pragma mark - autorotation

- (BOOL)shouldAutorotate
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationPortrait;
}

#pragma mark - collection view

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.items.count;
}

- (YPRSSItemInfo*)itemInfoForIndexPath:(NSIndexPath*)indexPath
{
	NSArray* items = self.items;
	return items.count > indexPath.row? items[indexPath.row] : nil;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	YPThumbCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
	
	[cell.imageView setImageWithURL:[NSURL URLWithString:[self itemInfoForIndexPath:indexPath].thumbnail.url]];
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	if (!_photoVC) {
		_photoVC = [YPPhotoVC new];
	}
	_photoVC.itemInfo = [self itemInfoForIndexPath:indexPath];
	[self.navigationController pushViewController:_photoVC animated:YES];
}

@end
