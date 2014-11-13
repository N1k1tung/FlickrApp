//
//  NetworkManager.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "NetworkManager.h"
#import "Configuration.h"

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
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}

#pragma mark - interface

- (void)requestSearchWithTag:(NSString*)tag onSuccess:(SuccessHandler)onSuccess onError:(FailureHandler)onError {
    [self makeRequest:[self searchWithTag:tag] onSuccess:onSuccess onError:onError];
}

#pragma mark - private

- (void)makeRequest:(NSURLRequest*)request onSuccess:(SuccessHandler)onSuccess onError:(FailureHandler)onError {
    
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
        NSLog(@"operation started");
        [task resume];
        dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
        NSLog(@"operation completed");
    }];
}

#pragma mark - requests

#pragma mark search
- (NSURLRequest*)searchWithTag:(NSString*)tag {

    
    // configure request
    static NSString* const method = @"flickr.photos.search";
    NSDictionary* params = @{@"method": method,
                             @"tags": tag,
                             @"api_key": [Configuration flickrApiKey]};
    NSString* query = [NSString stringWithFormat:@"%@?%@", [Configuration flickrEndpoint], [params requestParams]];
    // rely on db cache only
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:query] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    // accept json
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"GET"];
    
    return request;
}

#pragma mark images

- (NSURL*)urlForImageInfo:(NSDictionary*)info thumb:(BOOL)thumb {
    static NSString* const URLFormat = @"https://farm%@.staticflickr.com/%@/%@_%@_%@.jpg";
    return [NSURL URLWithString:[NSString stringWithFormat:URLFormat, info[@"farm-id"], info[@"server-id"], info[@"id"], info[@"secret"], thumb? @"q" : @"b"]];
}

- (NSURL*)urlForImageInfo:(NSDictionary*)info {
    return [self urlForImageInfo:info thumb:NO];
}

- (NSURL*)thumbURLForImageInfo:(NSDictionary*)info {
    return [self urlForImageInfo:info thumb:YES];
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