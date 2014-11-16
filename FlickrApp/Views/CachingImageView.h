//
//  CachingImageView.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//
#import <UIKit/UIKit.h>

/*!
 *  @class CachingImageView
 *  @discussion a nifty image view that handles caching and requesting for image if it's not present in cache
 *
 *  @author Nikita Rodin
 *  @version 1.0
 */
@interface CachingImageView : UIImageView <NSURLConnectionDataDelegate>

/*!
 @param imageURL the image URL
 @discussion sets the image, tries to find it in cache first
 */
- (void)setImageWithURL:(NSURL*)imageURL;

/*!
 @discussion default YES; avoid stockpiling large images in memory though
 */
@property (nonatomic, assign) BOOL useMemoryCache;

@end
