//  Copyright © Audulus LLC. Distributed under the MIT License.

#ifndef GetMetalLibrary_h
#define GetMetalLibrary_h

#import <Metal/Metal.h>

#ifdef __cplusplus
extern "C" {
#endif

id<MTLLibrary> MetalKernelsGetMetalLibrary(id<MTLDevice> device);

#ifdef __cplusplus
}
#endif

#endif /* GetMetalLibrary_h */
