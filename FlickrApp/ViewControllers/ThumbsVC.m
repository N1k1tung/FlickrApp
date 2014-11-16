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

@interface ThumbsVC () <NSFetchedResultsControllerDelegate>
{
	PhotoVC* _photoVC;
}

@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, strong) UIRefreshControl* refreshControl;

@property (nonatomic, strong) NSFetchedResultsController* fetchedResultsController;

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
    
    [[NetworkManager sharedManager] requestSearchWithTag:@"it" onSuccess:^(NSData *data) {
        // TODO: remove from main q
        dispatch_async(dispatch_get_main_queue(), ^{
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
            // TODO: remove
            [self.collectionView reloadData];
            
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
	return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationPortrait;
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
	
	[cell.imageView setImageWithURL:[[NetworkManager sharedManager] thumbURLForImageInfo:[self.fetchedResultsController objectAtIndexPath:indexPath]]];
	
	return cell;
}

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

//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
//{
//    if (controller != [self fetchedResultsController])
//        return;
//    
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
//           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
//{
//    if (controller != [self fetchedResultsController])
//        return;
//    
//    switch(type) {
//        case NSFetchedResultsChangeInsert:
//            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        default:
//            return;
//    }
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
//      newIndexPath:(NSIndexPath *)newIndexPath
//{
//    if (controller != [self fetchedResultsController])
//        return;
//    
//    UITableView *tableView = self.tableView;
//    
//    switch(type) {
//        case NSFetchedResultsChangeInsert:
//            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeUpdate:
//            [self configureCell:(ChallengeCell*)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
//            break;
//            
//        case NSFetchedResultsChangeMove:
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}
//
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (controller != [self fetchedResultsController])
        return;

    [self.collectionView reloadData];
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

@end
