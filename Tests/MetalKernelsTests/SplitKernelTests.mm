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

    uint expected[10] = { 0, 2, 4, 6, 8, 1, 3, 5, 7, 9};
    auto outPtr = (uint*) outBuf.contents;

    for(int i=0;i<n;++i) {
        XCTAssertEqual(outPtr[i], expected[i]);
    }

}


@end
