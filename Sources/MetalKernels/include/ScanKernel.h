//  Copyright © 2017 Halfspace LLC. All rights reserved.

#import <Metal/Metal.h>

/// Prefix sum for uint32 data.
@interface ScanKernel : NSObject

- (instancetype)init:(id<MTLDevice>)device;
- (void) encodeScanTo:(id<MTLCommandBuffer>)buffer
                input:(id<MTLBuffer>)inputBuf
               output:(id<MTLBuffer>)outputBuf
               length:(uint)length;

// For debugging.
- (id<MTLBuffer>) getAux;
- (id<MTLBuffer>) getAux2;

@end
