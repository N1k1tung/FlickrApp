//
//  ThumbCell.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "ThumbCell.h"

@implementation ThumbCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.imageView = [[CachingImageView alloc] initWithFrame:self.bounds];
		[self addSubview:_imageView];
	}
    return self;
}


@end
