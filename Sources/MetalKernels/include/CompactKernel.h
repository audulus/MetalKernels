//  Copyright © Audulus LLC. Distributed under the MIT License.

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

/// Stream compaction using a user-specified predicate.
@interface CompactKernel : NSObject

/// Create a CompactKernel.
- (instancetype)initWithDevice:(id<MTLDevice>)device;

/// Encodes commands to compact a buffer.
/// @param buffer command buffer for encoding
/// @param inputBuf input buffer of items
/// @param keep buffer of uint for whether to keep
/// @param outputBuf output buffer of compacted items
/// @param itemSize size of each item in bytes
/// @param length number of items in input buffer
///
/// After running, the final element of `getDest` is one less than the number of elements output.
- (void) encodeCompactTo:(id<MTLCommandBuffer>)buffer
                   input:(id<MTLBuffer>)inputBuf
                    keep:(id<MTLBuffer>)keep
                  output:(id<MTLBuffer>)outputBuf
                itemSize:(uint)itemSize
                  length:(uint)length;

@property uint maxLength;

// for debugging
- (id<MTLBuffer>) getDest;

@end

NS_ASSUME_NONNULL_END
