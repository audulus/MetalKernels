//  Copyright © 2017 Halfspace LLC. All rights reserved.

#import <XCTest/XCTest.h>
#import "ScanKernel.h"
#include <vector>

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
    int n = 1024*1024*256/4; // Max metal buffer size.
    
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
    
    uint* aux = (uint*) [kernel getAux].contents;
    
    for(int i=0;i<512;++i)
    {
        XCTAssertEqual(aux[i], 1024);
        if(aux[i] != 1024)
        {
            break;
        }
    }
    
    uint* aux2 = (uint*) [kernel getAux2].contents;
    
    for(int i=0;i<64;++i)
    {
        XCTAssertEqual(aux2[i], 1024*1024);
        if(aux2[i] != 1024*1024)
        {
            break;
        }
    }
    
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

    int n = 1024*1024*256/4; // Max metal buffer size.

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

@end
