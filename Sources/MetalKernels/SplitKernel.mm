//  Copyright © Audulus LLC. Distributed under the MIT License.

#import "SplitKernel.h"
#import "GetMetalLibrary.h"
#import "ScanKernel.h"
#import "scan.h"
#import "split.h"

@interface SplitKernel ()
{
    id<MTLComputePipelineState> prepPipeline;
    id<MTLComputePipelineState> scatterPipeline;
    id<MTLBuffer> eBuffer;
    id<MTLBuffer> fBuffer;
    ScanKernel* scanKernel;
}

@end

@implementation SplitKernel

- (instancetype)init:(id<MTLDevice>)device
{
    self = [super init];
    if (self) {

        auto lib = MetalKernelsGetMetalLibrary(device);
        prepPipeline = [self makeComputePipeline:@"split_prep" library:lib device:device];
        scatterPipeline = [self makeComputePipeline:@"split_scatter" library:lib device:device];
        scanKernel = [[ScanKernel alloc] init:device];
        eBuffer = [device newBufferWithLength:1024 options:MTLResourceStorageModePrivate];
        fBuffer = [device newBufferWithLength:1024 options:MTLResourceStorageModePrivate];

    }
    return self;
}

- (uint) maxLength {
    return uint(eBuffer.length / sizeof(uint));
}

- (void) setMaxLength:(uint)maxLength {
    if(eBuffer.length / sizeof(uint) != maxLength) {
        auto device = prepPipeline.device;
        auto bytes = maxLength * sizeof(uint);
        eBuffer = [device newBufferWithLength:bytes options:MTLResourceStorageModePrivate];
        fBuffer = [device newBufferWithLength:bytes options:MTLResourceStorageModePrivate];
    }
}

- (id<MTLComputePipelineState>) makeComputePipeline:(NSString*)name library:(id<MTLLibrary>) lib device:(id<MTLDevice>)device
{
    auto f = [lib newFunctionWithName:name];

    NSError* error = nil;
    auto state = [device newComputePipelineStateWithFunction:f error:&error];

    assert(error == nil);

    return state;

}

- (void) encodeSplitTo:(id<MTLCommandBuffer>)buffer
                 input:(id<MTLBuffer>)inputBuf
          inputIndices:(id<MTLBuffer>)inputIndexBuf
                output:(id<MTLBuffer>)outputBuf
         outputIndices:(id<MTLBuffer>)outputIndexBuf
                   bit:(uint)bit
                length:(uint)length
{
    assert(length <= eBuffer.length/sizeof(uint));

    auto encoder = [buffer computeCommandEncoder];

    [encoder setComputePipelineState:prepPipeline];

    [encoder setBuffer:inputBuf offset:0 atIndex:SplitBufferIndexInput];
    [encoder setBytes:&bit length:sizeof(uint) atIndex:SplitBufferIndexBit];
    [encoder setBuffer:eBuffer offset:0 atIndex:SplitBufferIndexE];
    [encoder setBytes:&length length:sizeof(uint) atIndex:SplitBufferIndexCount];

    [encoder dispatchThreadgroups:MTLSizeMake(length/SCAN_BLOCKSIZE+1, 1, 1) threadsPerThreadgroup:MTLSizeMake(SCAN_BLOCKSIZE, 1, 1)];

    [encoder endEncoding];

    [scanKernel encodeScanTo:buffer input:eBuffer output:fBuffer length:length];

    encoder = [buffer computeCommandEncoder];

    [encoder setComputePipelineState:scatterPipeline];

    [encoder setBuffer:inputBuf offset:0 atIndex:SplitBufferIndexInput];
    [encoder setBuffer:inputIndexBuf offset:0 atIndex:SplitBufferIndexInputIndices];
    [encoder setBuffer:outputBuf offset:0 atIndex:SplitBufferIndexOutput];
    [encoder setBuffer:outputIndexBuf offset:0 atIndex:SplitBufferIndexOutputIndices];
    [encoder setBytes:&bit length:sizeof(uint) atIndex:SplitBufferIndexBit];
    [encoder setBuffer:eBuffer offset:0 atIndex:SplitBufferIndexE];
    [encoder setBuffer:fBuffer offset:0 atIndex:SplitBufferIndexF];
    [encoder setBytes:&length length:sizeof(uint) atIndex:SplitBufferIndexCount];

    [encoder dispatchThreadgroups:MTLSizeMake(length/SCAN_BLOCKSIZE+1, 1, 1) threadsPerThreadgroup:MTLSizeMake(SCAN_BLOCKSIZE, 1, 1)];

    [encoder endEncoding];

}

@end
