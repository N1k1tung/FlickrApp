//
//  ThumbCell.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CachingImageView.h"

/*!
 @class ThumbCell
 @author Nikita Rodin
 @discussion simple collection view cell with a caching image view as only subview
 */
@interface ThumbCell : UICollectionViewCell

@property (nonatomic, strong) CachingImageView* imageView;

@end
