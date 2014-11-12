//
//  FlickrRequest.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "FlickrRequest.h"
#import "Configuration.h"

@interface NSDictionary (requestParams)

- (NSString*)requestParams;

@end

@implementation FlickrRequest

+ (instancetype)startWithTag:(NSString*)tag {
    FlickrRequest* wrapper = [FlickrRequest new];
    
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
    
    // configure session data task
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
    }];
    [task resume];
    
    return wrapper;
}

+ (NSURL*)urlForImageInfo:(NSDictionary*)info thumb:(BOOL)thumb {
    static NSString* const URLFormat = @"https://farm%@.staticflickr.com/%@/%@_%@_%@.jpg";
    return [NSURL URLWithString:[NSString stringWithFormat:URLFormat, info[@"farm-id"], info[@"server-id"], info[@"id"], info[@"secret"], thumb? @"q" : @"b"]];
}

+ (NSURL*)urlForImageInfo:(NSDictionary*)info {
    return [self urlForImageInfo:info thumb:NO];
}

+ (NSURL*)thumbURLForImageInfo:(NSDictionary*)info {
    return [self urlForImageInfo:info thumb:YES];
}


@end

