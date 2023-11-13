//  Copyright © Audulus LLC. Distributed under the MIT License.

#import "GetMetalLibrary.h"
#import "ScanKernel.h"

id<MTLLibrary> MetalKernelsGetMetalLibrary(id<MTLDevice> device) {

    // If we're building an xcframework, we won't have SWIFTPM_MODULE_BUNDLE.
#ifdef SWIFTPM_MODULE_BUNDLE
    NSBundle* bundle = SWIFTPM_MODULE_BUNDLE;
#else
    NSBundle* bundle = [NSBundle bundleForClass:ScanKernel.class];
#endif
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
