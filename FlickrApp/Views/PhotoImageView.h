//
//  YPPhotoImageView.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "CachingImageView.h"

@protocol PhotoImageViewDelegate;

@interface PhotoImageView : CachingImageView

@property (nonatomic, weak) id <PhotoImageViewDelegate> delegate;

@end


@protocol PhotoImageViewDelegate <NSObject>

@optional
- (void)imageViewDidLoadImage:(PhotoImageView*)imageView;
- (void)imageViewFailedToLoadImage:(PhotoImageView*)imageView;

@end
