//  Copyright © 2020 Audulus LLC. All rights reserved.

#import "GetMetalLibrary.h"

id<MTLLibrary> GetMetalLibrary(id<MTLDevice> device) {

    NSBundle* bundle = SWIFTPM_MODULE_BUNDLE;
    assert(bundle);

    NSURL* libraryURL = [bundle URLForResource:@"default" withExtension:@"metallib"];

    NSError* error;
    id<MTLLibrary> lib = [device newLibraryWithURL:libraryURL error:&error];
    if(error) {
        NSLog(@"error creating metal library: %@", lib);
    }

    assert(lib);
    return lib;
}
