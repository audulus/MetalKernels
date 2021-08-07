//  Copyright © 2021 Halfspace LLC. All rights reserved.

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
                output:(id<MTLBuffer>)outputBuf
                length:(uint)length
{
    for(int i=0;i<32;++i) {
        [splitKernel encodeSplitTo:buffer input:inputBuf output:outputBuf bit:i length:length];
        std::swap(inputBuf, outputBuf);
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
