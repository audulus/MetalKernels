//  Copyright © 2021 Halfspace LLC. All rights reserved.

#import "CompactKernel.h"
#import "GetMetalLibrary.h"

@interface CompactKernel ()
{
    id<MTLComputePipelineState> compactPipeline;
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

}

@end
