//
//  Configuration.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class Configuration
 @author Nikita Rodin
 @discussion Wrapper for app's configuration plist, all fields are self-explanatory
 */
@interface Configuration : NSObject

+ (NSString*)flickrApiKey;

+ (NSString*)flickrSecret;

+ (NSString*)flickrEndpoint;

@end
