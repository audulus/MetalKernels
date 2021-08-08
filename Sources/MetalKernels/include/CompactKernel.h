//  Copyright © 2021 Halfspace LLC. All rights reserved.

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

/// Stream compaction using a user-specified predicate.
@interface CompactKernel : NSObject

/// Create a CompactKernel.
/// @param predicate Metal function declared as [[visible]]. Must be bool functionName(device char*).
- (instancetype)initWithPredicate:(nonnull id<MTLFunction>)predicate;

/// Encodes commands to compact a buffer.
/// @param buffer command buffer for encoding
/// @param inputBuf input buffer of items
/// @param outputBuf output buffer of compacted items
/// @param itemSize size of each item in bytes
/// @param length number of items in input buffer
- (void) encodeCompactTo:(id<MTLCommandBuffer>)buffer
                   input:(id<MTLBuffer>)inputBuf
                  output:(id<MTLBuffer>)outputBuf
                itemSize:(uint)itemSize
                  length:(uint)length;

@property uint maxLength;

// for debugging
- (id<MTLBuffer>) getKeep;
- (id<MTLBuffer>) getDest;

@end

NS_ASSUME_NONNULL_END
