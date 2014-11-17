//
//  ThumbsVC.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "ThumbsVC.h"
#import "ThumbCell.h"
#import "PhotoVC.h"
#import <CoreData/CoreData.h>
#import "NetworkManager.h"
#import "AppDelegate.h"
#import "Photo.h"

/*!
 @discussion large thumbs layout
 */
@interface LargeThumbsFlow : UICollectionViewFlowLayout

@end

/*!
 @discussion default layout
 */
@interface ThreePerRowFlow : UICollectionViewFlowLayout

@end

/*!
 @discussion collection view update info
 */
@interface CollectionViewUpdate : NSObject

@property (nonatomic, strong) NSIndexPath* indexPath;
@property (nonatomic, strong) NSIndexPath* aNewIndexPath;
@property (nonatomic, assign) NSFetchedResultsChangeType type;

+ (instancetype)updateWithIndexPath:(NSIndexPath*)indexPath newIndexPath:(NSIndexPath*)newIndexPath type:(NSFetchedResultsChangeType)type;

@end

/*!
 @discussion collection view section update info
 */
@interface CollectionViewSectionUpdate : NSObject

@property (nonatomic, assign) NSUInteger sectionIndex;
@property (nonatomic, assign) NSFetchedResultsChangeType type;

+ (instancetype)updateWithSectionIndex:(NSUInteger)sectionIndex type:(NSFetchedResultsChangeType)type;

@end

@interface ThumbsVC () <NSFetchedResultsControllerDelegate>
{
	PhotoVC* _photoVC;
    
    // current layout
    BOOL _largeThumbsLayout;
}

@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, strong) UIRefreshControl* refreshControl;

@property (nonatomic, strong) NSFetchedResultsController* fetchedResultsController;

// batch updates
@property (nonatomic, strong) NSMutableArray* itemUpdates;
@property (nonatomic, strong) NSMutableArray* sectionUpdates;

@end

@implementation ThumbsVC

static NSString* const kCellID = @"collectionCell";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithCollectionViewLayout:[ThreePerRowFlow new]];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor redColor];
	[self.collectionView registerClass:[ThumbCell class] forCellWithReuseIdentifier:kCellID];
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
	
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"table"] style:UIBarButtonItemStylePlain target:self action:@selector(changeLayoutTapped)];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
	[self refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	_photoVC = nil;
}

- (void)refresh
{
    if (self.fetchedResultsController.sections.count == 0 || [[self.fetchedResultsController sections][0] numberOfObjects] == 0) { // empty
        [_activityIndicator startAnimating];
        [_refreshControl beginRefreshing];
    }
    
    [[NetworkManager sharedManager] requestSearchWithTag:@"it" onSuccess:^(NSData *data) {

            NSError* error = nil;
            
            // workaround the Flickr json response format
            NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            //remove the leading 'jsonFlickrFeed(' and trailing ')' from the response data so we are left with a dictionary root object
            NSInteger len = @"jsonFlickrApi(".length;
            NSString *correctedJSONString = [NSString stringWithString:[dataAsString substringWithRange:NSMakeRange (len, dataAsString.length-len-1)]];
            //Flickr incorrectly tries to escape single quotes - this is invalid JSON (see http://stackoverflow.com/a/2275428/423565)
            correctedJSONString = [correctedJSONString stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"];
            //re-encode the now correct string representation of JSON back to a NSData object which can be parsed by NSJSONSerialization
            NSData *correctedData = [correctedJSONString dataUsingEncoding:NSUTF8StringEncoding];

            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:correctedData options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"Warning" message:[NSString stringWithFormat:@"Error while parsing feed: %@", error.localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            } else
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([result respondsToSelector:@selector(objectForKeyedSubscript:)]) { // success, create models
                        NSArray* photos = result[@"photos"][@"photo"];
                        
                        for (NSDictionary* photo in photos) {
                            if (![photo respondsToSelector:@selector(objectForKeyedSubscript:)])
                                continue;
                            
                            // check for existing
                            Photo* photoDB = [self photoWithId:photo[@"id"]];
                            if (!photoDB) {
                                // create new
                                photoDB = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Photo class]) inManagedObjectContext:self.fetchedResultsController.managedObjectContext];
                            }
                            // update fields
                            photoDB.photo_id = photo[@"id"];
                            photoDB.title = photo[@"title"];
                            photoDB.farm = photo[@"farm"];
                            photoDB.server = photo[@"server"];
                            photoDB.secret = photo[@"secret"];
                            photoDB.owner = photo[@"owner"];
                        }
                    }
                    
                    [[AppDelegate sharedInstance] saveContext];
                    
                    [_activityIndicator stopAnimating];
                    [_refreshControl endRefreshing];
                });
    } onError:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:@"Warning" message:[NSString stringWithFormat:@"Error while loading feed: %@", error.localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            [_activityIndicator stopAnimating];
            [_refreshControl endRefreshing];
        });
    }];
   

}

#pragma mark - autorotation

- (BOOL)shouldAutorotate
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - collection view

// number of sections
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return self.fetchedResultsController.sections.count;
}

// number of items
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

// configure cell
- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	ThumbCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
	
    [self configureCell:cell atIndexPath:indexPath];
	
	return cell;
}

/*!
 @discussion configures specified cell
 */
- (void)configureCell:(ThumbCell*)cell atIndexPath:(NSIndexPath *)indexPath {
    Photo* imageInfo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [cell.imageView setImageWithURL:_largeThumbsLayout? [[NetworkManager sharedManager] largeThumbURLForImageInfo:imageInfo] : [[NetworkManager sharedManager] thumbURLForImageInfo:imageInfo]];
    cell.titleView.hidden = !_largeThumbsLayout;
    cell.titleView.text = imageInfo.title;
}

// cell selection
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	if (!_photoVC) {
		_photoVC = [PhotoVC new];
	}
	_photoVC.itemInfo = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[self.navigationController pushViewController:_photoVC animated:YES];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Photo class]) inManagedObjectContext:[[AppDelegate sharedInstance] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"photo_id" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[AppDelegate sharedInstance] managedObjectContext] sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[[UIAlertView alloc] initWithTitle:@"FATAL ERROR" message:@"Try restarting the app" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if (controller != [self fetchedResultsController])
        return;
 
    self.sectionUpdates = [NSMutableArray new];
    self.itemUpdates = [NSMutableArray new];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if (controller != [self fetchedResultsController])
        return;

    [self.sectionUpdates addObject:[CollectionViewSectionUpdate updateWithSectionIndex:sectionIndex type:type]];
    
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if (controller != [self fetchedResultsController])
        return;
    
    [self.itemUpdates addObject:[CollectionViewUpdate updateWithIndexPath:indexPath newIndexPath:newIndexPath type:type]];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (controller != [self fetchedResultsController])
        return;


    [self.collectionView performBatchUpdates:^{
        for (CollectionViewSectionUpdate* update in self.sectionUpdates) {
            switch(update.type) {
                case NSFetchedResultsChangeInsert:
                    [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:update.sectionIndex]];
                    break;
                    
                case NSFetchedResultsChangeDelete:
                    [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:update.sectionIndex]];
                    break;
                    
                default:
                    return;
            }
        }
        
        for (CollectionViewUpdate* update in self.itemUpdates) {
            switch(update.type) {
                case NSFetchedResultsChangeInsert:
                    [self.collectionView insertItemsAtIndexPaths:@[update.aNewIndexPath]];
                    break;
                    
                case NSFetchedResultsChangeDelete:
                    [self.collectionView deleteItemsAtIndexPaths:@[update.indexPath]];
                    break;
                    
                case NSFetchedResultsChangeUpdate:
                    [self configureCell:(ThumbCell*)[self.collectionView cellForItemAtIndexPath:update.indexPath] atIndexPath:update.indexPath];
                    break;
                    
                case NSFetchedResultsChangeMove:
                    [self.collectionView deleteItemsAtIndexPaths:@[update.indexPath]];
                    [self.collectionView insertItemsAtIndexPaths:@[update.aNewIndexPath]];
                    [self configureCell:(ThumbCell*)[self.collectionView cellForItemAtIndexPath:update.aNewIndexPath] atIndexPath:update.indexPath];
                    break;
            }

        }
        
    } completion:nil];
    
}

/*!
 @return photo with specified id
 @param photo_id photo id
 */
- (Photo*)photoWithId:(NSNumber*)photo_id {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext* context = self.fetchedResultsController.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Photo class]) inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"photo_id = %@", photo_id];
    [fetchRequest setPredicate:predicate];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:NULL];
    return [fetchedObjects lastObject];
}

#pragma mark - actions

// grid/table switch
- (void)changeLayoutTapped {
    _largeThumbsLayout = !_largeThumbsLayout;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:_largeThumbsLayout? @"grid" : @"table"] style:UIBarButtonItemStylePlain target:self action:@selector(changeLayoutTapped)];
    self.collectionView.collectionViewLayout = _largeThumbsLayout? [LargeThumbsFlow new] : [ThreePerRowFlow new];
    [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
}

@end


@implementation ThreePerRowFlow

- (instancetype)init {
    if (self = [super init]) {
        self.sectionInset = UIEdgeInsetsMake(4, 8, 4, 8);
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat itemWidth = (screenWidth-self.sectionInset.left-self.sectionInset.right) / 3.3; // 0.3 accounts for inter-item space
        self.itemSize = CGSizeMake(itemWidth, itemWidth);
        self.minimumLineSpacing = 15;
    }
    return self;
}


@end

@implementation LargeThumbsFlow

- (instancetype)init {
    if (self = [super init]) {
        self.sectionInset = UIEdgeInsetsMake(4, 8, 4, 8);
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat itemWidth = screenWidth-self.sectionInset.left-self.sectionInset.right;
        self.itemSize = CGSizeMake(itemWidth, itemWidth/16*9);
        self.minimumLineSpacing = 15;
    }
    return self;
}

@end


@implementation CollectionViewUpdate

+ (instancetype)updateWithIndexPath:(NSIndexPath*)indexPath newIndexPath:(NSIndexPath*)newIndexPath type:(NSFetchedResultsChangeType)type {
    CollectionViewUpdate* update = [CollectionViewUpdate new];
    update.indexPath = indexPath;
    update.aNewIndexPath = newIndexPath;
    update.type = type;
    return update;
}

@end


@implementation CollectionViewSectionUpdate

+ (instancetype)updateWithSectionIndex:(NSUInteger)sectionIndex type:(NSFetchedResultsChangeType)type {
    CollectionViewSectionUpdate* update = [CollectionViewSectionUpdate new];
    update.sectionIndex = sectionIndex;
    update.type = type;
    return update;
}

@end