//  Copyright © Audulus LLC. Distributed under the MIT License.

#import "RadixSortKernel.h"
#import "SplitKernel.h"

@interface RadixSortKernel ()
{
    SplitKernel* splitKernel;
}

@end

@implementation RadixSortKernel

- (instancetype)init:(id<MTLDevice>)device
{
    self = [super init];
    if (self) {
        splitKernel = [[SplitKernel alloc] init:device];
    }
    return self;
}

- (void) encodeSortTo:(id<MTLCommandBuffer>)buffer
                input:(id<MTLBuffer>)inputBuf
         inputIndices:(id<MTLBuffer>)inputIndicesBuf
               output:(id<MTLBuffer>)outputBuf
        outputIndices:(id<MTLBuffer>)outputIndicesBuf
               length:(uint)length
{
    for(int i=0;i<32;++i) {
        [splitKernel encodeSplitTo:buffer
                             input:inputBuf
                      inputIndices:inputIndicesBuf
                            output:outputBuf
                     outputIndices:outputIndicesBuf
                               bit:i
                            length:length];

        // Swap.
        auto tmp = inputBuf;
        inputBuf = outputBuf;
        outputBuf = tmp;

        tmp = inputIndicesBuf;
        inputIndicesBuf = outputIndicesBuf;
        outputIndicesBuf = tmp;
    }
    auto blit = [buffer blitCommandEncoder];
    [blit copyFromBuffer:inputBuf sourceOffset:0 toBuffer:outputBuf destinationOffset:0 size:length*sizeof(uint)];
    [blit endEncoding];
}

- (uint) maxLength {
    return splitKernel.maxLength;
}

- (void) setMaxLength:(uint)maxLength {
    splitKernel.maxLength = maxLength;
}

@end
