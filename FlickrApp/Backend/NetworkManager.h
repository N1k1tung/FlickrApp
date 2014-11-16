//
//  NetworkManager.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import <Foundation/Foundation.h>

// handlers are performed in background
typedef void (^SuccessHandler)(NSData* data);
typedef void (^FailureHandler)(NSError* error);

@class Photo;

/*!
 @class NetworkManager
 @author Nikita Rodin
 @discussion represents network operations manager
 */
@interface NetworkManager : NSObject

+ (instancetype)sharedManager;

/*!
 @discussion performs flickr search with specified tag
 @param tag the specified tag
 @param onSuccess successful response handler
 @param onError unsuccessful response handler
 */
- (void)requestSearchWithTag:(NSString*)tag onSuccess:(SuccessHandler)onSuccess onError:(FailureHandler)onError;


- (NSURL*)urlForImageInfo:(Photo*)info;
- (NSURL*)thumbURLForImageInfo:(Photo*)info;

@end

