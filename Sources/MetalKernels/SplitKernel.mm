//  Copyright © 2017 Halfspace LLC. All rights reserved.

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

        auto lib = GetMetalLibrary(device);
        prepPipeline = [self makeComputePipeline:@"split_prep" library:lib device:device];
        scatterPipeline = [self makeComputePipeline:@"split_scatter" library:lib device:device];
        scanKernel = [[ScanKernel alloc] init:device];
        eBuffer = [device newBufferWithLength:1024 options:MTLResourceStorageModeShared];
        fBuffer = [device newBufferWithLength:1024 options:MTLResourceStorageModeShared];

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

- (void) encodeSplitTo:(id<MTLCommandBuffer>)buffer
                 input:(id<MTLBuffer>)inputBuf
                output:(id<MTLBuffer>)outputBuf
                   bit:(uint)bit
                length:(uint)length
{

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
    [encoder setBuffer:outputBuf offset:0 atIndex:SplitBufferIndexOutput];
    [encoder setBytes:&bit length:sizeof(uint) atIndex:SplitBufferIndexBit];
    [encoder setBuffer:eBuffer offset:0 atIndex:SplitBufferIndexE];
    [encoder setBuffer:fBuffer offset:0 atIndex:SplitBufferIndexF];
    [encoder setBytes:&length length:sizeof(uint) atIndex:SplitBufferIndexCount];

    [encoder dispatchThreadgroups:MTLSizeMake(length/SCAN_BLOCKSIZE+1, 1, 1) threadsPerThreadgroup:MTLSizeMake(SCAN_BLOCKSIZE, 1, 1)];

    [encoder endEncoding];

}

- (id<MTLBuffer>) getE {
    return eBuffer;
}

- (id<MTLBuffer>) getF {
    return fBuffer;
}

@end
