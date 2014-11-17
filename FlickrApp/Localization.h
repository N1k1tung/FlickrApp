//
//  Localization.h
//  FlickrApp
//
//  Created by Nikita Rodin on 11/17/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class Localization
 @author Nikita Rodin
 @discussion provides custom localization
 */
@interface Localization : NSObject

/*!
 @param language en/ru
 @discussion sets current bundle to specified locale
 */
+ (void)setLanguage:(NSString *)language;

/*!
 @discussion use macro instead
 */
+ (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)alternate;

@end

// same usage as NSLocalizedString
#define MYLocalizedString(key, comment) \
[Localization localizedStringForKey:(key) value:@""]
