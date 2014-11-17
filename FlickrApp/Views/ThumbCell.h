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
 @class CoreTextView
 @author Nikita Rodin
 @discussion core text rendered label
 */
@interface CoreTextView : UIView

@property (nonatomic, copy) NSString* text;

@end

/*!
 @class ThumbCell
 @author Nikita Rodin
 @discussion simple collection view cell with a caching image view and a coreText-rendered title
 */
@interface ThumbCell : UICollectionViewCell

@property (nonatomic, strong) CachingImageView* imageView;
@property (nonatomic, strong) CoreTextView* titleView;

@end
