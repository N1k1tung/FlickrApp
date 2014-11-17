//
//  ImageCache.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "ImageCache.h"
#import "SDWebImageDecoder.h"
#import "Configuration.h"
#import "UIImage+FaceDetection.h"


#define IMAGES_DIR	[Configuration imagesDir]

@interface ImageCache ()

@property (strong) NSMutableDictionary* cachedImages;

@property (nonatomic, assign) BOOL diskCachingEnabled;
@property (nonatomic, strong) NSString* cachesDir;

@end

@implementation ImageCache

#pragma mark - singleton

+ (instancetype)sharedCache {
    static ImageCache *sharedCache = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[super allocWithZone:NULL] init];
    });
    
    return sharedCache;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedCache];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark - interface

- (void)cachedImageForURL:(NSURL*)imageURL onSuccess:(ImageProcessBlock)onSuccess onFail:(OnFailBlock)onFail useMemoryCache:(BOOL)useMemoryCache cropToSize:(CGSize)size
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString* cachePath = [self cachePathForURLString:imageURL.absoluteString];
        NSString* processedFilePath = [[[cachePath stringByDeletingPathExtension] stringByAppendingFormat:@"_%d_%d", (int)size.width, (int)size.height] stringByAppendingPathExtension:@"jpg"];
        UIImage* cachedImage = nil;
        if ((cachedImage = [self cachedImageForPath:CGSizeEqualToSize(size, CGSizeZero)? cachePath : processedFilePath useMemoryCache:useMemoryCache])) {
            if (onSuccess)
                dispatch_sync(dispatch_get_main_queue(), ^{
                    onSuccess(cachedImage);
                });
        } else {
            if (CGSizeEqualToSize(size, CGSizeZero)) {
                if (onFail)
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        onFail();
                    });
            } else // check if original is already in cache
            {
                if ((cachedImage = [self cachedImageForPath:cachePath useMemoryCache:useMemoryCache])) {
                    if (onSuccess)
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            onSuccess(cachedImage);
                        });
                } else {
                    if (onFail)
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            onFail();
                        });
                }
            }
            
        }
    });
}

- (UIImage*)cacheImage:(UIImage*)image forURL:(NSURL*)URL cacheToMemory:(BOOL)cacheToMemory cropToSize:(CGSize)size
{
    NSString* filePath = [self cachePathForURLString:URL.absoluteString];
    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        UIImage* processedImage = [image croppedToSize:size aroundLargestFaceWithAccuracy:CIDetectorAccuracyHigh];
        NSString* processedFilePath = [[[filePath stringByDeletingPathExtension] stringByAppendingFormat:@"_%d_%d", (int)size.width, (int)size.height] stringByAppendingPathExtension:@"jpg"];
        [self cacheImage:processedImage forFilePath:processedFilePath cacheToMemory:cacheToMemory];
        
        // don't cache the original in mem
        [self cacheImage:image forFilePath:filePath cacheToMemory:NO];
        return processedImage;
    }
    
    [self cacheImage:image forFilePath:filePath cacheToMemory:cacheToMemory];
    return image;
}

#pragma mark - init & clean cache

- (id)init
{
    if (self = [super init]) {
        self.cachedImages = [NSMutableDictionary new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanMemoryCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        self.cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        
        NSString* imagesDir = [_cachesDir stringByAppendingPathComponent:IMAGES_DIR];
        BOOL isDir = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagesDir isDirectory:&isDir] || !isDir) {
            NSError* error = nil;
            if (![[NSFileManager defaultManager] createDirectoryAtPath:imagesDir withIntermediateDirectories:YES attributes:nil error:&error])
                NSLog(@"%s: Failed to create directory for image cache: %@", __PRETTY_FUNCTION__, error);
            else
                self.diskCachingEnabled = YES;
        } else
            self.diskCachingEnabled = YES;
    }
    return self;
}

- (void)cleanMemoryCache
{
    [self.cachedImages removeAllObjects];
}

#pragma mark - internal

- (NSString*)cachePathForURLString:(NSString*)urlString
{
    if (!_cachesDir.length)
        self.cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString* fileName = [[urlString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/:.?"]] componentsJoinedByString:@""];
    if (fileName.length)
        fileName = [fileName substringFromIndex:MAX(0, fileName.length-20)]; // up to 20 last chars
    return [_cachesDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.jpg", IMAGES_DIR, fileName]];
}

- (void)cacheImage:(UIImage*)image forFilePath:(NSString*)filePath cacheToMemory:(BOOL)cacheToMemory {
    if (filePath.length)
    {
        if (cacheToMemory)
            [self memCacheImage:image forPath:filePath];
        if (self.diskCachingEnabled)
            [UIImageJPEGRepresentation(image, 1.0f) writeToFile:filePath atomically:YES];
    }
}

- (UIImage*)cachedImageForPath:(NSString*)filePath useMemoryCache:(BOOL)useMemoryCache
{
    UIImage* cachedImage = nil;
    if (useMemoryCache && (cachedImage = [self memCachedImageForPath:filePath]))
        return cachedImage;
    
    if (!_diskCachingEnabled || ![[NSFileManager new] fileExistsAtPath:filePath])
        return nil;
    cachedImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath]];
    cachedImage = [UIImage decodedImageWithImage:cachedImage];
    if (cachedImage && useMemoryCache)
        [self memCacheImage:cachedImage forPath:filePath];
    return cachedImage;
}

- (UIImage*)memCachedImageForPath:(NSString*)filePath
{
    return self.cachedImages[filePath];
}

- (void)memCacheImage:(UIImage*)image forPath:(NSString*)filePath
{
    self.cachedImages[filePath] = image;
}


@end