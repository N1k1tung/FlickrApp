//
//  FlickrRequest.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class FlickrRequest
 @author Nikita Rodin
 @discussion simple wrapper for flickr REST API
 */
@interface FlickrRequest : NSObject

+ (instancetype)startWithTag:(NSString*)tag;

@end