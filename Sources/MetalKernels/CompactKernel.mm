//  Copyright © Audulus LLC. Distributed under the MIT License.

#import "CompactKernel.h"
#import "GetMetalLibrary.h"
#import "ScanKernel.h"
#import "scan.h"

@interface CompactKernel ()
{
    id<MTLComputePipelineState> scatterPipeline;
    id<MTLBuffer> destBuffer;
    ScanKernel* scanKernel;
}

@end

@implementation CompactKernel

- (instancetype)initWithDevice:(nonnull id<MTLDevice>)device
{
    self = [super init];
    if (self) {
        auto lib = MetalKernelsGetMetalLibrary(device);

        destBuffer = [device newBufferWithLength:1024 options:MTLResourceStorageModeShared];

        scanKernel = [[ScanKernel alloc] init:device];

        scatterPipeline = [self makeComputePipeline:@"compact_scatter" library:lib device:device];
    }
    return self;
}

- (id<MTLComputePipelineState>) makeComputePipeline:(NSString*)name library:(id<MTLLibrary>) lib device:(id<MTLDevice>)device
{
    auto f = [lib newFunctionWithName:name];

    NSError* error = nil;
    auto state = [device newComputePipelineStateWithFunction:f error:&error];

    assert(error == nil);

    return state;

}

- (void) encodeCompactTo:(id<MTLCommandBuffer>)buffer
                   input:(id<MTLBuffer>)inputBuf
                    keep:(id<MTLBuffer>)keepBuf
                  output:(id<MTLBuffer>)outputBuf
                itemSize:(uint)itemSize
                  length:(uint)length {

    assert(length * sizeof(uint) <= keepBuf.length);

    [scanKernel encodeScanTo:buffer input:keepBuf output:destBuffer length:length];

    auto enc = [buffer computeCommandEncoder];
    [enc setComputePipelineState:scatterPipeline];
    [enc setBuffer:inputBuf offset:0 atIndex:0];
    [enc setBytes:&itemSize length:sizeof(uint) atIndex:1];
    [enc setBytes:&length length:sizeof(uint) atIndex:2];
    [enc setBuffer:keepBuf offset:0 atIndex:3];
    [enc setBuffer:destBuffer offset:0 atIndex:4];
    [enc setBuffer:outputBuf offset:0 atIndex:5];

    [enc dispatchThreadgroups:MTLSizeMake(length/SCAN_BLOCKSIZE+1, 1, 1) threadsPerThreadgroup:MTLSizeMake(SCAN_BLOCKSIZE, 1, 1)];
    [enc endEncoding];

}

- (uint) maxLength {
    return uint(destBuffer.length / sizeof(uint));
}

- (void) setMaxLength:(uint)maxLength {
    if(destBuffer.length / sizeof(uint) != maxLength) {
        auto device = scatterPipeline.device;
        auto bytes = maxLength * sizeof(uint);
        destBuffer = [device newBufferWithLength:bytes options:MTLResourceStorageModeShared];
    }
}

- (id<MTLBuffer>) getDest {
    return destBuffer;
}

@end
