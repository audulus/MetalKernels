//  Copyright © 2021 Halfspace LLC. All rights reserved.

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface CompactKernel : NSObject

- (instancetype)initWithPredicate:(nonnull id<MTLFunction>)predicate;

- (void) encodeCompactTo:(id<MTLCommandBuffer>)buffer
                   input:(id<MTLBuffer>)inputBuf
                  output:(id<MTLBuffer>)outputBuf
                itemSize:(uint)itemSize
                  length:(uint)length;

// for debugging
- (id<MTLBuffer>) getKeep;
- (id<MTLBuffer>) getDest;

@end

NS_ASSUME_NONNULL_END
