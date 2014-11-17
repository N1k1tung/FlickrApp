//
//  NetworkManager.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "NetworkManager.h"
#import "Configuration.h"
#import "Photo.h"

@interface NetworkManager () {
    /*!
     @discussion queue for downloads
     */
    NSOperationQueue* _downloadQueue;
    /*!
     @discussion queue for response handlers
     */
    NSOperationQueue* _processingQueue;
    NSURLSession* _session;
}

@end

@interface NSDictionary (requestParams)

- (NSString*)requestParams;

@end

@implementation NetworkManager

#pragma mark - singleton

+ (instancetype)sharedManager {
    static NetworkManager *sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[super allocWithZone:NULL] init];
    });
    
    return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedManager];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 5;
        _processingQueue = [NSOperationQueue new];
        _processingQueue.maxConcurrentOperationCount = 5;
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}

#pragma mark - interface

- (void)requestSearchWithTag:(NSString*)tag onSuccess:(SuccessHandler)onSuccess onError:(FailureHandler)onError {
    [self makeRequest:[self searchWithTag:tag] onSuccess:onSuccess onError:onError];
}

- (NSURLSessionDataTask*)requestImageWithURL:(NSURL*)url onSuccess:(SuccessHandler)onSuccess onError:(FailureHandler)onError {
    return [self makeRequest:[NSURLRequest requestWithURL:url] onSuccess:onSuccess onError:onError];
}

- (NSURL*)urlForImageInfo:(Photo*)info {
    return [self urlForImageInfo:info size:ImageSizeBig];
}

- (NSURL*)thumbURLForImageInfo:(Photo*)info {
    return [self urlForImageInfo:info size:ImageSizeSmallThumb];
}

- (NSURL*)largeThumbURLForImageInfo:(Photo*)info {
    return [self urlForImageInfo:info size:ImageSizeLargeThumb];
}

#pragma mark - private

- (NSURLSessionDataTask*)makeRequest:(NSURLRequest*)request onSuccess:(SuccessHandler)onSuccess onError:(FailureHandler)onError {
    
    // lock operation in queue until it receives response
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    
    // configure session data task
    NSURLSessionDataTask* task = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_semaphore_signal(lock);
        // error
        if (error || [(NSHTTPURLResponse*)response statusCode] != 200) {
            if (onError)
                [_processingQueue addOperationWithBlock:^{
                    onError(error);
                }];
        } else
        // success
        {
            if (onSuccess)
                [_processingQueue addOperationWithBlock:^{
                    onSuccess(data);
                }];
        }
    }];
    
    [_downloadQueue addOperationWithBlock:^{
        [task resume];
        dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    }];
    return task;
}

#pragma mark - requests

#pragma mark search
- (NSURLRequest*)searchWithTag:(NSString*)tag {

    
    // configure request
    static NSString* const method = @"flickr.photos.search";
    NSDictionary* params = @{@"method": method,
                             @"tags": tag,
                             @"api_key": [Configuration flickrApiKey],
                             @"format" : @"json"}; // nice...
    NSString* query = [NSString stringWithFormat:@"%@?%@", [Configuration flickrEndpoint], [params requestParams]];
    // rely on db cache only
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:query] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    // accept json
    // and here we thought flickr rest service would be actually rest...
//    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"GET"];
    
    return request;
}

#pragma mark images

typedef NS_ENUM(NSUInteger, ImageSize) {
    ImageSizeSmallThumb,
    ImageSizeLargeThumb,
    ImageSizeBig,
};

- (NSURL*)urlForImageInfo:(Photo*)info size:(ImageSize)size {
    static NSString* const URLFormat = @"https://farm%@.staticflickr.com/%@/%@_%@_%@.jpg";
    return [NSURL URLWithString:[NSString stringWithFormat:URLFormat, info.farm, info.server, info.photo_id, info.secret, size == ImageSizeSmallThumb? @"q" : size == ImageSizeLargeThumb? @"n" : @"b"]];
}

@end

/*!
 @discussion extension for dictionary representation of request params
 */
@implementation NSDictionary (requestParams)

- (NSString*)requestParams {
    NSMutableArray* keyValues = [NSMutableArray new];
    for (id param in self) {
        [keyValues addObject:[NSString stringWithFormat:@"%@=%@", param, self[param]]];
    }
    return [keyValues componentsJoinedByString:@"&"];
}

@end