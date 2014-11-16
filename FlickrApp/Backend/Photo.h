//
//  Photo.h
//  FlickrApp
//
//  Created by n1k1tung on 11/17/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Photo : NSManagedObject

@property (nonatomic, retain) NSString * photo_id;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSString * secret;
@property (nonatomic, retain) NSString * server;
@property (nonatomic, retain) NSNumber * farm;
@property (nonatomic, retain) NSString * title;

@end
