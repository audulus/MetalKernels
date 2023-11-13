//  Copyright © Audulus LLC. Distributed under the MIT License.

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

    std::vector<uint> idx(n);
    for(int i=0;i<n;++i) {
        idx[i] = i;
    }

    auto inIndicesBuf = [device newBufferWithBytes:idx.data() length:idx.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outIndicesBuf = [device newBufferWithLength:idx.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];

    [kernel encodeSortTo:buf
                   input:inBuf
            inputIndices:inIndicesBuf
                  output:outBuf
           outputIndices:outIndicesBuf
                  length:n];

    [buf commit];
    [buf waitUntilCompleted];

    auto outPtr = (uint*) outBuf.contents;

    for(int i=0;i<n;++i) {
        XCTAssertEqual(outPtr[i], i);
    }

    auto outIndicesPtr = (uint*) outIndicesBuf.contents;
    for(int i=0;i<n;++i) {
        XCTAssertEqual(outIndicesPtr[i], n-i-1);
    }

}

// Many iOS devices have a max buffer size of 256MB.
#define MAX_BUFFER_SIZE (256*1024*1024)

- (void)testRadixSort2 {

    int n = MAX_BUFFER_SIZE/sizeof(uint);
    std::vector<uint> vec(n);
    for(int i=0;i<n;++i) {
        vec[i] = rand();
    }

    [kernel setMaxLength:n];

    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    std::vector<uint> idx(n);
    for(int i=0;i<n;++i) {
        idx[i] = i;
    }

    auto inIndicesBuf = [device newBufferWithBytes:idx.data() length:idx.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outIndicesBuf = [device newBufferWithLength:idx.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];

    [kernel encodeSortTo:buf
                   input:inBuf
            inputIndices:inIndicesBuf
                  output:outBuf
           outputIndices:outIndicesBuf
                  length:n];

    [buf commit];
    [buf waitUntilCompleted];
    printf("GPU radix sort time: %f\n", buf.GPUEndTime - buf.GPUStartTime);

    auto outPtr = (uint*) outBuf.contents;

    auto start = [NSDate date];
    std::sort(vec.begin(), vec.end());
    printf("std::sort time: %f\n", [[NSDate date] timeIntervalSinceDate:start]);

    for(int i=0;i<n;++i) {
        XCTAssertEqual(outPtr[i], vec[i]);
        if(outPtr[i] != vec[i]) {
            break;
        }
    }

}

@end
