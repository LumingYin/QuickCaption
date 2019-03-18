//
//  QuickCaptionScrollView.m
//  Quick Caption
//
//  Created by Blue on 3/18/19.
//  Copyright © 2019 Bright. All rights reserved.
//

#import "QuickCaptionScrollView.h"

@implementation QuickCaptionScrollView

- (void)awakeFromNib {
    self.scrollerStyle = NSScrollerStyleLegacy;
}

- (void)setScrollerStyle:(NSScrollerStyle)scrollerStyle {
    [super setScrollerStyle:NSScrollerStyleLegacy];
}

@end
