//  Copyright © 2021 Halfspace LLC. All rights reserved.

#import <XCTest/XCTest.h>
#import "RadixSortKernel.h"
#include <vector>

@interface RadixSortKernelTests : XCTestCase {
    id<MTLDevice> device;
    id<MTLCommandQueue> queue;
    RadixSortKernel* kernel;
}

@end

@implementation RadixSortKernelTests

- (void)setUp {
    device = MTLCreateSystemDefaultDevice();
    queue = [device newCommandQueue];
    kernel = [[RadixSortKernel alloc] init:device];
}


- (void)testRadixSort {

    int n = 10;
    std::vector<uint> vec(n);
    for(int i=0;i<n;++i) {
        vec[i] = n-i-1;
    }

    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];

    [kernel encodeSortTo:buf input:inBuf output:outBuf length:n];

    [buf commit];
    [buf waitUntilCompleted];

    auto outPtr = (uint*) outBuf.contents;

    for(int i=0;i<n;++i) {
        XCTAssertEqual(outPtr[i], i);
    }

}

@end
