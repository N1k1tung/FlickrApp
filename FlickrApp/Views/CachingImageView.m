//
//  CachingImageView.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "CachingImageView.h"
#import "ImageCache.h"
#import "NetworkManager.h"

@interface CachingImageView () {
}

@property (nonatomic, strong) NSURL* url;
@property (nonatomic, weak) NSURLSessionDataTask* dataTask;

@end

@implementation CachingImageView

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
		self.useMemoryCache = YES;
	}
	return self;
}

#pragma mark - custom set image

- (void)setImageWithURL:(NSURL*)imageURL
{
    [self.dataTask cancel];
    
	self.image = nil;
	if (!imageURL)
		return;
		
	[[ImageCache sharedCache] cachedImageForURL:imageURL onSuccess:^(UIImage *cachedImage) {
		self.image = cachedImage;
	} onFail:^{
		[self startRequestWithURL:imageURL];
	} useMemoryCache:_useMemoryCache];
}

- (void)startRequestWithURL:(NSURL*)imageURL
{
    self.url = imageURL;
	self.dataTask = [[NetworkManager sharedManager] requestImageWithURL:imageURL onSuccess:^(NSData *data) {
        UIImage *image = [UIImage imageWithData:data];
        if (image)
            [[ImageCache sharedCache] cacheImage:image forURL:_url cacheToMemory:_useMemoryCache];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = image;
        });
    } onError:^(NSError *error) {
        if (![error.localizedDescription isEqualToString:@"cancelled"])
            NSLog(@"Error loading image at URL %@: %@", _url.absoluteString, error.localizedDescription);
    }];
    
}

- (void)setImage:(UIImage *)image
{
	[super setImage:image? image : [UIImage imageNamed:@"blankImage"]];
}

@end


