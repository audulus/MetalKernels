//  Copyright © 2021 Halfspace LLC. All rights reserved.

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadixSortKernel : NSObject

- (instancetype)init:(id<MTLDevice>)device;
- (void) encodeSortTo:(id<MTLCommandBuffer>)buffer
                 input:(id<MTLBuffer>)inputBuf
                output:(id<MTLBuffer>)outputBuf
                length:(uint)length;

@end

NS_ASSUME_NONNULL_END
