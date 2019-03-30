@import Foundation;
@import AppKit;

@interface NSObject (KVO)

- (void)safelyRemoveObserver:(nonnull NSObject *)observer forKeyPath:(nonnull NSString *)keyPath;
- (NSURL* _Nonnull)applicationDataDirectory;
@end

@interface NSImage(saveAsJpegWithName)
- (void)saveAsJpegWithName:(NSString* _Nonnull) fileName;
- (void)saveAsFileWithType:(NSBitmapImageFileType)type withName:(NSString* _Nonnull)fileName;
@end

