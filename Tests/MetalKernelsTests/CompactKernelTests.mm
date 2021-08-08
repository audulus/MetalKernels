//  Copyright © 2021 Halfspace LLC. All rights reserved.

#import <XCTest/XCTest.h>
#import "CompactKernel.h"
#import "../../Sources/MetalKernels/GetMetalLibrary.h"
#include <vector>

@interface CompactKernelTests : XCTestCase {
    id<MTLDevice> device;
    id<MTLCommandQueue> queue;
    CompactKernel* kernel;
}

@end

@implementation CompactKernelTests

- (void)setUp {
    device = MTLCreateSystemDefaultDevice();
    queue = [device newCommandQueue];
    auto lib = GetMetalLibrary(device);
    assert(lib);
    auto fn = [lib newFunctionWithName:@"is_odd"];
    assert(fn);
    kernel = [[CompactKernel alloc] initWithPredicate:fn];
}

- (void)testCompact {

    int n = 10;
    std::vector<uint> vec(n);
    for(int i=0;i<n;++i) {
        vec[i] = i;
    }

    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];

    [kernel encodeCompactTo:buf input:inBuf output:outBuf itemSize:sizeof(uint) length:n];

    [buf commit];
    [buf waitUntilCompleted];

    auto outPtr = (uint*) outBuf.contents;
    auto keepPtr = (uint*) [kernel getKeep].contents;
    auto destPtr = (uint*) [kernel getDest].contents;

    printf("out:\n");
    for(int i=0;i<n;++i) {
        printf("%d: %d\n", i, outPtr[i]);
    }

    printf("keep:\n");
    for(int i=0;i<n;++i) {
        printf("%d: %d\n", i, keepPtr[i]);
    }

    printf("dest:\n");
    for(int i=0;i<n;++i) {
        printf("%d: %d\n", i, destPtr[i]);
    }
}

@end
