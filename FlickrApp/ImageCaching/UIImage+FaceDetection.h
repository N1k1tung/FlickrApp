//
//  Photo.h
//  FlickrApp
//
//  Created by n1k1tung on 11/17/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface UIImage (FaceDetection)

// preserves aspect
- (UIImage *)croppedToSize:(CGSize)size aroundLargestFaceWithAccuracy:(NSString *)detectorAccuracy;

@end
