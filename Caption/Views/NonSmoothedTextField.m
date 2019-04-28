//
//  NonSmoothedTextField.m
//  Quick Caption
//
//  Created by Blue on 4/28/19.
//  Copyright © 2019 Bright. All rights reserved.
//

#import "NonSmoothedTextField.h"

@implementation NonSmoothedTextField

- (void)drawRect:(NSRect)dirtyRect {
    if (@available(macOS 10.14, *)) {
    } else {
        [[NSGraphicsContext currentContext] setShouldAntialias:YES];
        CGContextSetShouldAntialias((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], YES);
        CGContextSetShouldSmoothFonts((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], NO);
    }
    [super drawRect:dirtyRect];
}

@end
