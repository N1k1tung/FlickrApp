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
@property (nonatomic, assign) CGSize cropSize;

@end

@implementation CachingImageView

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
		self.useMemoryCache = YES;
        self.opaque = YES;
	}
	return self;
}

#pragma mark - custom set image

- (void)setImageWithURL:(NSURL*)imageURL cropSize:(CGSize)size
{

	self.image = nil;
	if (!imageURL)
		return;

    self.cropSize = size;
    
	[[ImageCache sharedCache] cachedImageForURL:imageURL onSuccess:^(UIImage *cachedImage) {
        self.image = cachedImage;
    } onFail:^{
        [self startRequestWithURL:imageURL];
    } useMemoryCache:_useMemoryCache cropToSize:size];
}

- (void)setImageWithURL:(NSURL*)imageURL {
    [self setImageWithURL:imageURL cropSize:CGSizeZero];
}

- (void)setCroppedImageWithURL:(NSURL*)imageURL {
    CGSize size = self.bounds.size;
    size.width *= self.contentScaleFactor;
    size.height *= self.contentScaleFactor;
    [self setImageWithURL:imageURL cropSize:size];
}

- (void)startRequestWithURL:(NSURL*)imageURL
{
    self.url = imageURL;
	self.dataTask = [[NetworkManager sharedManager] requestImageWithURL:imageURL onSuccess:^(NSData *data) {
        UIImage *image = [UIImage imageWithData:data];
        if (image)
            image = [[ImageCache sharedCache] cacheImage:image forURL:_url cacheToMemory:_useMemoryCache cropToSize:_cropSize];

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


