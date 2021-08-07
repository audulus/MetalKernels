//  Copyright © 2021 Halfspace LLC. All rights reserved.

#import <XCTest/XCTest.h>
#import "SplitKernel.h"
#include <vector>

@interface Test : XCTestCase

@end

@implementation Test


- (void)testSplitKernel {
    auto device = MTLCreateSystemDefaultDevice();

    auto kernel = [[SplitKernel alloc] init:device];

    int n = 10;
    std::vector<uint> vec(n);
    for(int i=0;i<n;++i) {
        vec[i] = i;
    }

    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto queue = [device newCommandQueue];

    auto buf = [queue commandBuffer];

    [kernel encodeSplitTo:buf input:inBuf output:outBuf bit:0 length:n];

    [buf commit];
    [buf waitUntilCompleted];

    auto outPtr = (uint*) outBuf.contents;
    printf("output:\n");
    for(int i=0;i<n;++i) {
        printf("%d: %d\n", i, outPtr[i]);
    }

    auto ePtr = (uint*) [kernel getE].contents;
    printf("e:\n");
    for(int i=0;i<n;++i) {
        printf("%d: %d\n", i, ePtr[i]);
    }

    auto fPtr = (uint*) [kernel getF].contents;
    printf("f:\n");
    for(int i=0;i<n;++i) {
        printf("%d: %d\n", i, fPtr[i]);
    }
}


@end
