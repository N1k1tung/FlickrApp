//
//  ThumbCell.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/12/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "ThumbCell.h"
#import <CoreText/CoreText.h>

@implementation ThumbCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.imageView = [[CachingImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.layer.masksToBounds = true;
		[self addSubview:_imageView];
        
        self.titleView = [[CoreTextView alloc] initWithFrame:CGRectMake(4, 4, self.bounds.size.width, self.bounds.size.height/4)];
        self.titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.titleView.backgroundColor = [UIColor clearColor];
        [self addSubview:_titleView];
	}
    return self;
}


@end


@implementation CoreTextView

// setup text changes observing
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"text" context:NULL];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Flip the coordinate system
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // path to draw text in
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds );
    
    NSAttributedString* attString = [[NSAttributedString alloc] initWithString:self.text attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    // draw frame
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [attString length]), path, NULL);
    CTFrameDraw(frame, context);
    
    // cleanup
    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);
}

// observe text changes
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self setNeedsDisplay];
}

@end