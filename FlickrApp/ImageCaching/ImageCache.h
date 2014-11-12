//
//  ImageCache.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ImageProcessBlock)(UIImage* cachedImage);
typedef void (^OnFailBlock)();

@interface ImageCache : NSObject

+ (instancetype)sharedCache;

- (void)cachedImageForURL:(NSURL*)URL onSuccess:(ImageProcessBlock)onSuccess onFail:(OnFailBlock)onFail useMemoryCache:(BOOL)useMemoryCache;
- (void)cachedImageForURL:(NSURL*)URL onSuccess:(ImageProcessBlock)onSuccess onFail:(OnFailBlock)onFail;
- (void)cacheImage:(UIImage*)image forURL:(NSURL*)URL cacheToMemory:(BOOL)cacheToMemory;
- (void)cacheImage:(UIImage*)image forURL:(NSURL*)URL;

@end
