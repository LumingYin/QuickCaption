@import Foundation;

@interface NSObject (KVO)

- (void)safelyRemoveObserver:(nonnull NSObject *)observer forKeyPath:(nonnull NSString *)keyPath;

@end
