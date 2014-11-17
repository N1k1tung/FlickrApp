/*
 Released under ISC (similar to 2-clause BSD)
 
 http://wikipedia.org/wiki/ISC_license
 */

#import <UIKit/UIKit.h>

@interface UIImage (FaceDetection)

- (NSArray *)facesWithAccuracy :(NSString *)detectorAccuracy;
- (CIFaceFeature *)largestFaceWithAccuracy :(NSString *)detectorAccuracy;
- (UIImage *)croppedToSize:(CGSize)size aroundLargestFaceWithAccuracy:(NSString *)detectorAccuracy;

@end
