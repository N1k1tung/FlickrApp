//
//  NetworkManager.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "NetworkManager.h"

@implementation NetworkManager

#pragma mark - singleton

+ (instancetype)sharedManager {
    static NetworkManager *sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[super allocWithZone:NULL] init];
    });
    
    return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedManager];
}


- (id)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark - requests



@end
