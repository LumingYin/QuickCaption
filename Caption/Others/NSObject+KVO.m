#import "NSObject+KVO.h"

@implementation NSObject (KVO)

- (void)safelyRemoveObserver:(nonnull NSObject *)observer forKeyPath:(nonnull NSString *)keyPath
{
    @try {
        [self removeObserver:observer forKeyPath:keyPath];
    } @catch (NSException * __unused exception) {
        // nothing to do
    }
}

@end