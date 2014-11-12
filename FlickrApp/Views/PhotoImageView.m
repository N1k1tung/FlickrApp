//
//  PhotoImageView.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "PhotoImageView.h"

@implementation PhotoImageView

- (void)setImage:(UIImage *)image
{
	[super setImage:image];
	if (image) {
		self.frame = CGRectMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.frame), image.size.width, image.size.height);
		if ([_delegate respondsToSelector:@selector(imageViewDidLoadImage:)])
			[_delegate imageViewDidLoadImage:self];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[super connection:connection didFailWithError:error];
	if ([_delegate respondsToSelector:@selector(imageViewFailedToLoadImage:)])
		[_delegate imageViewFailedToLoadImage:self];
}

@end
