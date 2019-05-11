//
//  NSString+Additions.m
//  Quick Caption
//
//  Created by blue on 5/2/19.
//  Copyright © 2019 Bright. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Additions)

-(NSString*)stringByTruncatingToWidth:(CGFloat)width withFont:(NSFont*)font
{
    int min = 0, max = self.length, mid;
    while (min < max) {
        mid = (min+max)/2;
        
        NSString *currentString = [self substringWithRange:NSMakeRange(0, mid)];
        
//        let width = NSAttributedString(string: pendingCaption, attributes: [.font: self.captionPreviewLabel.font]).size().width

        CGSize currentSize = [currentString sizeWithFont:font];
        
        if (currentSize.width < width){
            min = mid + 1;
        } else if (currentSize.width > width) {
            max = mid - 1;
        } else {
            min = mid;
            break;
        }
    }
    return [self substringWithRange:NSMakeRange(0, min)];
}


@end
