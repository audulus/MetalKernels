//  Copyright © Audulus LLC. Distributed under the MIT License.

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
    kernel = [[CompactKernel alloc] initWithDevice:device];
}

- (void)testCompact {

    XCTAssertTrue(device.supportsFunctionPointers);

    int n = 10;
    std::vector<uint> vec(n);
    std::vector<uint> odd(n);
    for(int i=0;i<n;++i) {
        vec[i] = i;
        odd[i] = i % 2;
    }

    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto keepBuf = [device newBufferWithBytes:odd.data() length:odd.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];

    [kernel encodeCompactTo:buf input:inBuf keep:keepBuf output:outBuf itemSize:sizeof(uint) length:n];

    [buf commit];
    [buf waitUntilCompleted];

    auto outPtr = (uint*) outBuf.contents;
    auto destPtr = (uint*) [kernel getDest].contents;
    auto keepPtr = (uint*) keepBuf.contents;

    uint expected[10] = { 1, 3, 5, 7, 9, 0, 0, 0, 0, 0 };

    for(int i=0;i<n;++i) {
        XCTAssertEqual(outPtr[i], expected[i]);
    }

    XCTAssertEqual(destPtr[9], 4);
}

// Many iOS devices have a max buffer size of 256MB.
#define MAX_BUFFER_SIZE (256*1024*1024)

- (void) testCompact2 {

    int n = MAX_BUFFER_SIZE/sizeof(uint);

    kernel.maxLength = n;

    std::vector<uint> vec(n);
    std::vector<uint> odd(n);
    for(int i=0;i<n;++i)
    {
        vec[i] = i;
        odd[i] = i % 2;
    }

    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto keepBuf = [device newBufferWithBytes:odd.data() length:odd.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];

    [kernel encodeCompactTo:buf input:inBuf keep:keepBuf output:outBuf itemSize:sizeof(uint) length:n];

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

    printf("GPU time %f\n", (float) (buf.GPUEndTime - buf.GPUStartTime));

    std::vector<uint> compacted;
    compacted.reserve(n);
    auto start = [NSDate date];
    for(int i=0;i<n;++i) {
        if(vec[i] & 1) {
            compacted.push_back(vec[i]);
        }
    }
    XCTAssertEqual(compacted[0], 1);
    printf("CPU time %f\n", (float) [[NSDate date] timeIntervalSinceDate:start]);

    auto destPtr = (uint*) [kernel getDest].contents;

    XCTAssertEqual(destPtr[n-1], n/2-1);
}

@end
