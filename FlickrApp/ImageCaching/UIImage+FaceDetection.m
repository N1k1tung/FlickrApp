//
//  Photo.h
//  FlickrApp
//
//  Created by n1k1tung on 11/17/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "UIImage+FaceDetection.h"

@implementation UIImage (FaceDetection)

- (NSArray *)facesWithAccuracy :(NSString *)detectorAccuracy {
    CIImage *coreImageRepresentation = [[CIImage alloc] initWithImage:self];

    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:[NSDictionary dictionaryWithObject:detectorAccuracy forKey:CIDetectorAccuracy]];

    NSArray *features = [detector featuresInImage:coreImageRepresentation];

    return features;
}

- (CIFaceFeature *)largestFaceWithAccuracy :(NSString *)detectorAccuracy {
    
    NSArray *faces = [self facesWithAccuracy:detectorAccuracy];
    
    float currentLargestWidth = 0;
    CIFaceFeature *largestFace = nil;
    
    for (CIFaceFeature *face in faces) {
        if (face.bounds.size.width > currentLargestWidth) {
            largestFace = face;
            currentLargestWidth = face.bounds.size.width;
        }
    }
    
    return largestFace;
}

- (UIImage *)croppedToSize:(CGSize)size aroundLargestFaceWithAccuracy:(NSString *)detectorAccuracy {
    CIFaceFeature *largestFace = [self largestFaceWithAccuracy:detectorAccuracy];
    
    // defaults to center
    CGPoint center = CGPointMake(self.size.width/2, self.size.height/2);
    
    // center on face if present
    if (largestFace) {
        center.x = CGRectGetMidX(largestFace.bounds);
        center.y = CGRectGetMidY(largestFace.bounds);
    }
    
    double ratio;
    double delta;
    CGPoint offset;
    
    //figure out if the picture is landscape or portrait, then calculate scale factor and offset
    if (self.size.width > self.size.height) {
        ratio = size.width / self.size.width;
        delta = (ratio*self.size.width - ratio*self.size.height);
        offset = CGPointMake(delta/2 + center.x - self.size.width/2, 0 + center.y - self.size.height/2);
    } else {
        ratio = size.height / self.size.height;
        delta = (ratio*self.size.height - ratio*self.size.width);
        offset = CGPointMake(0 + center.x - self.size.width/2, delta/2 + center.y - self.size.height/2);
    }
    
    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(offset.x, offset.y,
                                 (ratio * self.size.width) + delta,
                                 (ratio * self.size.height) + delta);

    CIImage *coreImage = [[CIImage alloc] initWithImage:self];
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *faceImage = [coreImage imageByCroppingToRect:clipRect];
    UIImage *croppedImage = [UIImage imageWithCGImage:[context createCGImage:faceImage
                                                                    fromRect:faceImage.extent]];
    
    return croppedImage;

}

@end