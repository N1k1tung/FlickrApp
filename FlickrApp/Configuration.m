//
//  Configuration.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "Configuration.h"

@implementation Configuration

static NSDictionary* dict = nil;

+ (void)initialize {
    dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Configuration" ofType:@"plist"]];
}

+ (NSString*)flickrApiKey {
    return dict[@"flickrApiKey"];
}

+ (NSString*)flickrSecret {
    return dict[@"flickrSecret"];
}

+ (NSString*)flickrEndpoint {
    return dict[@"flickrEndpoint"];
}

+ (NSString*)imagesDir {
    return dict[@"imagesDir"];
}

@end
