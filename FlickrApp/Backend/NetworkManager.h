//
//  NetworkManager.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^successHandler)();
typedef void (^failureHandler)(NSError* error);

/*!
 @class NetworkManager
 @author Nikita Rodin
 @discussion represents network operations manager
 */
@interface NetworkManager : NSObject

+ (instancetype)sharedManager;



@end

