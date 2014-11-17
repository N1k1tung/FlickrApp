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

/*!
 @class ImageCache
 @author Nikita Rodin
 @discussion fascilitates image caching (to memory, disk)
 */
@interface ImageCache : NSObject

+ (instancetype)sharedCache;

/*!
 @discussion size = CGSizeZero => no crop
 */
- (void)cachedImageForURL:(NSURL*)URL onSuccess:(ImageProcessBlock)onSuccess onFail:(OnFailBlock)onFail useMemoryCache:(BOOL)useMemoryCache cropToSize:(CGSize)size;
/*!
 @return cropped image
 */
- (UIImage*)cacheImage:(UIImage*)image forURL:(NSURL*)URL cacheToMemory:(BOOL)cacheToMemory cropToSize:(CGSize)size;

@end
