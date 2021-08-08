//  Copyright © 2021 Halfspace LLC. All rights reserved.

#import "CompactKernel.h"
#import "GetMetalLibrary.h"
#import "ScanKernel.h"
#import "scan.h"

@interface CompactKernel ()
{
    id<MTLComputePipelineState> compactPipeline;
    id<MTLComputePipelineState> scatterPipeline;
    id<MTLBuffer> keepBuffer;
    id<MTLBuffer> destBuffer;
    ScanKernel* scanKernel;
}

@end

@implementation CompactKernel

- (instancetype)initWithPredicate:(nonnull id<MTLFunction>)predicate
{
    self = [super init];
    if (self) {
        auto device = predicate.device;
        auto lib = GetMetalLibrary(device);

        auto linkedFunctions = [[MTLLinkedFunctions alloc] init];

        linkedFunctions.functions = @[ predicate ];

        auto descriptor = [[MTLComputePipelineDescriptor alloc] init];

        // Set the main compute function.
        descriptor.computeFunction = [lib newFunctionWithName:@"compact_prep"];

        // Attach the linked functions object to the compute pipeline descriptor.
        descriptor.linkedFunctions = linkedFunctions;

        // Set to YES to allow the compiler to make certain optimizations.
        descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;

        NSError *error = nil;

        // Create the compute pipeline state.
        compactPipeline = [device newComputePipelineStateWithDescriptor:descriptor
                                                                 options:0
                                                              reflection:nil
                                                                   error:&error];

        if (!compactPipeline) {
            NSLog(@"Failed to create pipeline state: %@", error.localizedDescription);
            return nil;
        }

        keepBuffer = [device newBufferWithLength:1024 options:MTLResourceStorageModePrivate];
        destBuffer = [device newBufferWithLength:1024 options:MTLResourceStorageModePrivate];

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
                  output:(id<MTLBuffer>)outputBuf
                itemSize:(uint)itemSize
                  length:(uint)length {

    auto enc = [buffer computeCommandEncoder];
    [enc setComputePipelineState:compactPipeline];
    [enc setBuffer:inputBuf offset:0 atIndex:0];
    [enc setBuffer:keepBuffer offset:0 atIndex:1];
    [enc setBytes:&itemSize length:sizeof(uint) atIndex:2];
    [enc setBytes:&length length:sizeof(uint) atIndex:3];
    [enc dispatchThreadgroups:MTLSizeMake(length/SCAN_BLOCKSIZE+1, 1, 1) threadsPerThreadgroup:MTLSizeMake(SCAN_BLOCKSIZE, 1, 1)];
    [enc endEncoding];

    [scanKernel encodeScanTo:buffer input:keepBuffer output:destBuffer length:length];

    enc = [buffer computeCommandEncoder];
    [enc setComputePipelineState:scatterPipeline];
    [enc setBuffer:inputBuf offset:0 atIndex:0];
    [enc setBytes:&itemSize length:sizeof(uint) atIndex:1];
    [enc setBytes:&length length:sizeof(uint) atIndex:2];
    [enc setBuffer:keepBuffer offset:0 atIndex:3];
    [enc setBuffer:destBuffer offset:0 atIndex:4];
    [enc setBuffer:outputBuf offset:0 atIndex:5];

    [enc dispatchThreadgroups:MTLSizeMake(length/SCAN_BLOCKSIZE+1, 1, 1) threadsPerThreadgroup:MTLSizeMake(SCAN_BLOCKSIZE, 1, 1)];
    [enc endEncoding];

}

@end
