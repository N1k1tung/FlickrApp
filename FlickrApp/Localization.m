//
//  Localization.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/17/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "Localization.h"

@implementation Localization

static NSBundle *bundle = nil;

+ (void)initialize {
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    [self setLanguage:[defs stringForKey:@"locale"]];
}

+ (void)setLanguage:(NSString *)l {
    NSString *path = [[NSBundle mainBundle] pathForResource:l ofType:@"lproj" ];
    bundle = [NSBundle bundleWithPath:path];
}

+ (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)alternate {
    return [bundle localizedStringForKey:key value:alternate table:nil];
}


@end
