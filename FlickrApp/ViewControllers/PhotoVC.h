//
//  PhotoVC.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoImageView.h"

@class RSSItemInfo;

@interface PhotoVC : UIViewController <PhotoImageViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) RSSItemInfo* itemInfo;

@end
