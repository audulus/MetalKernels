//  Copyright © Audulus LLC. Distributed under the MIT License.

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

/// Radix sort for uint32 data.
@interface RadixSortKernel : NSObject

- (instancetype)init:(id<MTLDevice>)device;
- (void) encodeSortTo:(id<MTLCommandBuffer>)buffer
                input:(id<MTLBuffer>)inputBuf
         inputIndices:(id<MTLBuffer>)inputIndicesBuf
               output:(id<MTLBuffer>)outputBuf
         outputIndices:(id<MTLBuffer>)outputIndicesBuf
               length:(uint)length;

@property uint maxLength;

@end

NS_ASSUME_NONNULL_END
