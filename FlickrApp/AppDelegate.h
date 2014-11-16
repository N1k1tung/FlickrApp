//
//  AppDelegate.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 *  @class AppDelegate
 *  @discussion the delegate responder for the application
 *
 *  @author Nikita Rodin
 *  @version 1.0
 */
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSArray *managedObjectContexts;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (AppDelegate*)sharedInstance;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
/*!
 @return moc for current thread
 */
- (NSManagedObjectContext*)managedObjectContext;


@end
