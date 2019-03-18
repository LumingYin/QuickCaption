#import "NSObject+KVO.h"

@implementation NSImage(saveAsJpegWithName)

- (void)saveAsJpegWithName:(NSString*) fileName
{
    [self saveAsFileWithType:NSJPEGFileType withName:fileName];
}

- (void)saveAsFileWithType:(NSBitmapImageFileType)type withName:(NSString *)fileName {
    // Cache the reduced image
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:type properties:imageProps];
    [imageData writeToFile:[fileName stringByExpandingTildeInPath] atomically:NO];
}
@end


@implementation NSObject (KVO)

- (void)safelyRemoveObserver:(nonnull NSObject *)observer forKeyPath:(nonnull NSString *)keyPath
{
    @try {
        [self removeObserver:observer forKeyPath:keyPath];
    } @catch (NSException * __unused exception) {
        // nothing to do
    }
}

- (NSURL*)applicationDataDirectory {
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSArray* possibleURLs = [sharedFM URLsForDirectory:NSApplicationSupportDirectory
                                             inDomains:NSUserDomainMask];
    NSURL* appSupportDir = nil;
    NSURL* appDirectory = nil;

    if ([possibleURLs count] >= 1) {
        // Use the first directory (if multiple are returned)
        appSupportDir = [possibleURLs objectAtIndex:0];
    }

    // If a valid app support directory exists, add the
    // app's bundle ID to it to specify the final directory.
    if (appSupportDir) {
        NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
        appDirectory = [appSupportDir URLByAppendingPathComponent:appBundleID];
    }

    return appDirectory;
}

@end
