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

/*!
 @class NetworkManager
 @author Nikita Rodin
 @discussion represents network operations manager
 */
@interface NetworkManager : NSObject

+ (instancetype)sharedManager;

- (void)requestSearchWithTag:(NSString*)tag onSuccess:(SuccessHandler)onSuccess onError:(FailureHandler)onError;


@end

