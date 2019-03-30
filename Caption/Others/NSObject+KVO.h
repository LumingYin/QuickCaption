@import Foundation;
@import AppKit;

@interface NSObject (KVO)

- (void)safelyRemoveObserver:(nonnull NSObject *)observer forKeyPath:(nonnull NSString *)keyPath;
- (NSURL*)applicationDataDirectory;
-(NSString *)comboBoxAlert;
@end

@interface NSImage(saveAsJpegWithName)
- (void) saveAsJpegWithName:(NSString*) fileName;
- (void)saveAsFileWithType:(NSBitmapImageFileType)type withName:(NSString *)fileName;
@end

