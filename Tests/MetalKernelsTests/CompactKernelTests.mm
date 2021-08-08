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

    uint expected[10] = { 1, 3, 5, 7, 9, 0, 0, 0, 0, 0 };

    for(int i=0;i<n;++i) {
        XCTAssertEqual(outPtr[i], expected[i]);
    }
}

// Many iOS devices have a max buffer size of 256MB.
#define MAX_BUFFER_SIZE (256*1024*1024)

- (void) testCompact2 {

    int n = MAX_BUFFER_SIZE/sizeof(uint);

    kernel.maxLength = n;

    std::vector<uint> vec(n);
    for(int i=0;i<n;++i)
    {
        vec[i] = i;
    }

    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];

    [kernel encodeCompactTo:buf input:inBuf output:outBuf itemSize:sizeof(uint) length:n];

    [buf commit];
    [buf waitUntilCompleted];

    auto outPtr = (uint*) outBuf.contents;

    for(int i=0;i<n;++i) {
        auto x = outPtr[i];
        XCTAssertTrue(x == 0 || (x & 1));
        if(!(x==0 || (x&1))) {
            break;
        }
    }
}

@end
