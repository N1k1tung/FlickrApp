//
//  CachingImageView.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface CachingImageView : UIImageView <NSURLConnectionDataDelegate>

- (void)setImageWithURL:(NSURL*)imageURL;

@property (nonatomic, assign) BOOL useMemoryCache; // default YES; avoid stockpiling large images in memory

@end
