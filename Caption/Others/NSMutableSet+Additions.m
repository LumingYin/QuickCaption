//
//  NSMutableSet+Additions.m
//  Quick Caption
//
//  Created by Blue on 4/28/19.
//  Copyright © 2019 Bright. All rights reserved.
//

#import "NSMutableSet+Additions.h"
@import ObjectiveC;

@implementation NSMutableSet (Additions)

+ (void)load {
    if (@available(macOS 10.12, *)) {
    } else {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Class class = [self class];

            SEL originalSelector = @selector(minusSet:);
            SEL swizzledSelector = @selector(swz_minusSet:);

            Method originalMethod = class_getInstanceMethod(class, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

            // When swizzling a class method, use the following:
            // Class class = object_getClass((id)self);
            // ...
            // Method originalMethod = class_getClassMethod(class, originalSelector);
            // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);

            BOOL didAddMethod =
            class_addMethod(class,
                            originalSelector,
                            method_getImplementation(swizzledMethod),
                            method_getTypeEncoding(swizzledMethod));

            if (didAddMethod) {
                class_replaceMethod(class,
                                    swizzledSelector,
                                    method_getImplementation(originalMethod),
                                    method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        });
    }
}

- (void)swz_minusSet:(id)arg1 {
    NSString *argType = NSStringFromClass([arg1 class]);
    NSSet *set;
    BOOL shouldPrint = YES;
    if ([arg1 isKindOfClass:[NSMutableOrderedSet class]]) {
        set = ((NSMutableOrderedSet *)arg1).set;
    } else if ([arg1 isKindOfClass:[NSOrderedSet class]]) {
        set = ((NSOrderedSet *)arg1).set;
    } else if ([arg1 isKindOfClass:[NSMutableSet class]]) {
        set = [((NSMutableSet *)arg1) copy];
    } else if ([arg1 isKindOfClass:[NSSet class]]) {
        set = arg1;
    } else {
        set = [[NSSet alloc] initWithObjects:arg1, nil];
    }
    if (shouldPrint) {
        NSLog(@"swz_intersectsSet: %@, arg: %@ of type %@, converted: %@", self, arg1, argType, set);
    }
    @try {
        [self swz_minusSet:set];
    } @catch (NSException *e) {
        NSLog(@"Caught exception: %@", e);
    }
}

@end
