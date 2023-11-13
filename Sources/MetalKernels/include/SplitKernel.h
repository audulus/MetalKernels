//  Copyright © 2017 Halfspace LLC. All rights reserved.

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

/// Kernel for the split operation, which is a single
/// step of a radix sort. int32 values are sorted by the i-th bit.
@interface SplitKernel : NSObject

- (instancetype)init:(id<MTLDevice>)device;

/// Encode GPU commands for the split operation.
/// - Parameters:
///   - buffer: command buffer where commands are encoded
///   - inputBuf: input buffer of int32s to be split
///   - outputBuf: output buffer where int32s are written
///   - bit: pivot bit (output will be sorted by this bit)
///   - length: number of int32s to be split
- (void) encodeSplitTo:(id<MTLCommandBuffer>)buffer
                 input:(id<MTLBuffer>)inputBuf
                output:(id<MTLBuffer>)outputBuf
                   bit:(uint)bit
                length:(uint)length;

@property uint maxLength;

@end

NS_ASSUME_NONNULL_END
