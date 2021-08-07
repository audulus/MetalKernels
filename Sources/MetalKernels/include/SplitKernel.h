//  Copyright © 2017 Halfspace LLC. All rights reserved.

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface SplitKernel : NSObject

- (instancetype)init:(id<MTLDevice>)device;
- (void) encodeSplitTo:(id<MTLCommandBuffer>)buffer
                 input:(id<MTLBuffer>)inputBuf
                output:(id<MTLBuffer>)outputBuf
                   bit:(uint)bit
                length:(uint)length;

// For debugging.
- (id<MTLBuffer>) getE;
- (id<MTLBuffer>) getF;

@end

NS_ASSUME_NONNULL_END
