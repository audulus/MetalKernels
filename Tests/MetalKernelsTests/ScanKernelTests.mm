//  Copyright © Audulus LLC. Distributed under the MIT License.

#import <XCTest/XCTest.h>
#import "ScanKernel.h"
#include <vector>

// Many iOS devices have a max buffer size of 256MB.
#define MAX_BUFFER_SIZE (256*1024*1024)

@interface ScanKernelTests : XCTestCase {
    id<MTLDevice> device;
    id<MTLCommandQueue> queue;
    ScanKernel* kernel;
}

@end

@implementation ScanKernelTests

- (void)setUp {
    device = MTLCreateSystemDefaultDevice();
    queue = [device newCommandQueue];
    kernel = [[ScanKernel alloc] init:device];
}

- (void)testScan
{
    int n = MAX_BUFFER_SIZE/sizeof(uint);
    
    std::vector<uint> vec(n);
    for(int i=0;i<n;++i)
    {
        vec[i] = 1;
    }
    
    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];
    
    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];
    
    [kernel encodeScanTo:buf input:inBuf output:outBuf length:n];
    
    [buf commit];
    [buf waitUntilCompleted];
    
    uint* result = (uint*) outBuf.contents;
    
    for(int i=0;i<n;++i)
    {
        XCTAssertEqual(result[i], i);
        if(result[i] != i)
        {
            break;
        }
    }
}

- (void) testSmallScan {

    int n = 10;

    std::vector<uint> vec(n);
    for(int i=0;i<n;++i)
    {
        vec[i] = 1;
    }

    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];

    [kernel encodeScanTo:buf input:inBuf output:outBuf length:n];

    [buf commit];
    [buf waitUntilCompleted];

    uint* result = (uint*) outBuf.contents;

    for(int i=0;i<n;++i)
    {
        XCTAssertEqual(result[i], i);
        if(result[i] != i)
        {
            break;
        }
    }
}

- (void) testScan2 {

    int n = MAX_BUFFER_SIZE/sizeof(uint);

    std::vector<uint> vec(n);
    for(int i=0;i<n;++i)
    {
        vec[i] = rand() % 10;
    }

    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];

    [kernel encodeScanTo:buf input:inBuf output:outBuf length:n];

    [buf commit];
    [buf waitUntilCompleted];

    uint* result = (uint*) outBuf.contents;

    uint sum = 0;
    for(int i=0;i<n;++i)
    {
        XCTAssertEqual(result[i], sum);
        if(result[i] != sum)
        {
            break;
        }
        sum += vec[i];
    }
}

- (void)testScanKernelPerf
{
    int n = 1000*1000; // 1m elements
    
    std::vector<uint> vec(n);
    for(int i=0;i<n;++i)
    {
        vec[i] = 1;
    }
    
    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];
    
    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    // Warm up.
    for(int i=0;i<10;++i)
    {
        auto buf = [queue commandBuffer];
        [kernel encodeScanTo:buf input:inBuf output:outBuf length:n];
        [buf commit];
        [buf waitUntilCompleted];
    }
    
    [self measureBlock:^{
        auto buf = [queue commandBuffer];
        
        [kernel encodeScanTo:buf input:inBuf output:outBuf length:n];
        
        [buf commit];
        [buf waitUntilCompleted];
    }];
    
}

- (void)testScanIndirect
{
    int n = MAX_BUFFER_SIZE/sizeof(uint);

    std::vector<uint> vec(n);
    for(int i=0;i<n;++i)
    {
        vec[i] = 1;
    }

    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto lenBuf = [device newBufferWithBytes:&n length:sizeof(int) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];

    [kernel encodeScanIndirectTo:buf input:inBuf output:outBuf length:lenBuf];

    [buf commit];
    [buf waitUntilCompleted];

    uint* result = (uint*) outBuf.contents;

    for(int i=0;i<n;++i)
    {
        XCTAssertEqual(result[i], i);
        if(result[i] != i)
        {
            break;
        }
    }
}

- (void) testScanIndirect2 {

    int n = MAX_BUFFER_SIZE/sizeof(uint);

    std::vector<uint> vec(n);
    for(int i=0;i<n;++i)
    {
        vec[i] = rand() % 10;
    }

    auto inBuf = [device newBufferWithBytes:vec.data() length:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto outBuf = [device newBufferWithLength:vec.size()*sizeof(uint) options:MTLResourceStorageModeShared];

    auto lenBuf = [device newBufferWithBytes:&n length:sizeof(int) options:MTLResourceStorageModeShared];

    auto buf = [queue commandBuffer];

    [kernel encodeScanIndirectTo:buf input:inBuf output:outBuf length:lenBuf];

    [buf commit];
    [buf waitUntilCompleted];

    uint* result = (uint*) outBuf.contents;

    uint sum = 0;
    for(int i=0;i<n;++i)
    {
        XCTAssertEqual(result[i], sum);
        if(result[i] != sum)
        {
            break;
        }
        sum += vec[i];
    }
}

@end
