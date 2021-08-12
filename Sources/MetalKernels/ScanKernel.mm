//  Copyright © 2017 Halfspace LLC. All rights reserved.

#import "ScanKernel.h"
#import "GetMetalLibrary.h"
#import "scan.h"

@interface ScanKernel ()
{

    id<MTLBuffer> auxBuffer;
    id<MTLBuffer> auxScanBuffer;
    id<MTLBuffer> aux2Buffer;
    id<MTLBuffer> aux2ScanBuffer;
    id<MTLBuffer> aux3Buffer;
    id<MTLBuffer> indirectArgsBuffer;
    id<MTLBuffer> lengthsBuffer;
    
    id<MTLComputePipelineState> scanPipeline;
    id<MTLComputePipelineState> fixupPipeline;
    id<MTLComputePipelineState> threadgroupsPipeline;
}

@end

@implementation ScanKernel

- (instancetype)init:(id<MTLDevice>)device
{
    self = [super init];
    if (self) {
        
        auxBuffer = [device newBufferWithLength:(1024*1024*10) options:MTLResourceStorageModePrivate];
        auxScanBuffer = [device newBufferWithLength:(1024*1024*10) options:MTLResourceStorageModePrivate];
        aux2Buffer = [device newBufferWithLength:(1024*1024*2) options:MTLResourceStorageModePrivate];
        aux2ScanBuffer = [device newBufferWithLength:(1024*1024*2) options:MTLResourceStorageModePrivate];
        aux3Buffer = [device newBufferWithLength:(1024) options:MTLResourceStorageModePrivate];
        indirectArgsBuffer = [device newBufferWithLength:3*sizeof(MTLDispatchThreadgroupsIndirectArguments) options:MTLResourceStorageModePrivate];
        lengthsBuffer = [device newBufferWithLength:3*sizeof(uint) options:MTLResourceStorageModePrivate];
        
        auto lib = GetMetalLibrary(device);
        scanPipeline = [self makeComputePipeline:@"prefixSum" library:lib device:device];
        fixupPipeline = [self makeComputePipeline:@"prefixFixup" library:lib device:device];
        threadgroupsPipeline = [self makeComputePipeline:@"scan_threadgroups" library:lib device:device];
        
    }
    return self;
}

- (id<MTLComputePipelineState>) makeComputePipeline:(NSString*)name library:(id<MTLLibrary>) lib device:(id<MTLDevice>)device
{
    auto f = [lib newFunctionWithName:name];
    
    NSError* error = nil;
    auto state = [device newComputePipelineStateWithFunction:f error:&error];
    
    assert(error == nil);
    
    return state;
    
}

- (void) encodeScanLevelTo:(id<MTLCommandBuffer>)buffer
                     input:(id<MTLBuffer>)inputBuf
                    output:(id<MTLBuffer>)outputBuf
                    aux:(id<MTLBuffer>)auxBuf
                    length:(uint)length
{
    auto encoder = [buffer computeCommandEncoder];
    
    encoder.label = @"scan";
    
    [encoder setComputePipelineState:scanPipeline];
    
    [encoder setBuffer:inputBuf offset:0 atIndex:ScanBufferIndexInput];
    [encoder setBuffer:outputBuf offset:0 atIndex:ScanBufferIndexOutput];
    [encoder setBuffer:auxBuf offset:0 atIndex:ScanBufferIndexAux];
    [encoder setBytes:&length length:sizeof(uint) atIndex:ScanBufferIndexLength];
    
    int zon = 1;
    [encoder setBytes:&zon length:sizeof(int) atIndex:ScanBufferIndexZeroff];
    
    assert( outputBuf.length >= inputBuf.length );
    assert( length/SCAN_BLOCKSIZE+1 < auxBuf.length/sizeof(uint));
    
    [encoder dispatchThreadgroups:MTLSizeMake(length/SCAN_BLOCKSIZE+1, 1, 1) threadsPerThreadgroup:MTLSizeMake(SCAN_BLOCKSIZE, 1, 1)];
    
    [encoder endEncoding];
}

- (void) encodeFixupTo:(id<MTLCommandBuffer>)buffer
                   input:(id<MTLBuffer>)inputBuf
                     aux:(id<MTLBuffer>)auxBuf
                  length:(uint)length
{
    
    auto encoder = [buffer computeCommandEncoder];
    
    [encoder setComputePipelineState:fixupPipeline];
    
    [encoder setBuffer:inputBuf offset:0 atIndex:ScanBufferIndexInput];
    [encoder setBuffer:auxBuf offset:0 atIndex:ScanBufferIndexAux];
    [encoder setBytes:&length length:sizeof(uint) atIndex:ScanBufferIndexLength];
    
    [encoder dispatchThreadgroups:MTLSizeMake(length/SCAN_BLOCKSIZE+1, 1, 1) threadsPerThreadgroup:MTLSizeMake(SCAN_BLOCKSIZE, 1, 1)];
    
    [encoder endEncoding];
    
}

- (void) encodeScanTo:(id<MTLCommandBuffer>)buffer
                input:(id<MTLBuffer>)inputBuf
               output:(id<MTLBuffer>)outputBuf
               length:(uint)length;
{
    
    [self encodeScanLevelTo:buffer input:inputBuf output:outputBuf aux:auxBuffer length:length];
    
    [self encodeScanLevelTo:buffer input:auxBuffer output:auxScanBuffer aux:aux2Buffer length:length/SCAN_BLOCKSIZE];
    [self encodeScanLevelTo:buffer input:aux2Buffer output:aux2ScanBuffer aux:aux3Buffer length:SCAN_BLOCKSIZE];
    
    [self encodeFixupTo:buffer input:auxScanBuffer aux:aux2ScanBuffer length:length/SCAN_BLOCKSIZE];
    [self encodeFixupTo:buffer input:outputBuf aux:auxScanBuffer length:length];
    
}

- (void) encodeScanIndirectLevelTo:(id<MTLCommandBuffer>)buffer
                             input:(id<MTLBuffer>)inputBuf
                            output:(id<MTLBuffer>)outputBuf
                               aux:(id<MTLBuffer>)auxBuf
                         argsIndex:(uint)argsIndex
{
    auto encoder = [buffer computeCommandEncoder];

    encoder.label = @"scan";

    [encoder setComputePipelineState:scanPipeline];

    [encoder setBuffer:inputBuf offset:0 atIndex:ScanBufferIndexInput];
    [encoder setBuffer:outputBuf offset:0 atIndex:ScanBufferIndexOutput];
    [encoder setBuffer:auxBuf offset:0 atIndex:ScanBufferIndexAux];
    [encoder setBuffer:lengthsBuffer offset:argsIndex*sizeof(uint) atIndex:ScanBufferIndexLength];

    int zon = 1;
    [encoder setBytes:&zon length:sizeof(int) atIndex:ScanBufferIndexZeroff];

    assert( outputBuf.length >= inputBuf.length );

    [encoder dispatchThreadgroupsWithIndirectBuffer:indirectArgsBuffer
                               indirectBufferOffset:argsIndex*sizeof(MTLDispatchThreadgroupsIndirectArguments)
                              threadsPerThreadgroup:MTLSizeMake(SCAN_BLOCKSIZE, 1, 1)];

    [encoder endEncoding];
}

- (void) encodeFixupIndirectTo:(id<MTLCommandBuffer>)buffer
                   input:(id<MTLBuffer>)inputBuf
                     aux:(id<MTLBuffer>)auxBuf
               argsIndex:(uint)argsIndex
{

    auto encoder = [buffer computeCommandEncoder];

    [encoder setComputePipelineState:fixupPipeline];

    [encoder setBuffer:inputBuf offset:0 atIndex:ScanBufferIndexInput];
    [encoder setBuffer:auxBuf offset:0 atIndex:ScanBufferIndexAux];
    [encoder setBuffer:lengthsBuffer offset:argsIndex*sizeof(uint) atIndex:ScanBufferIndexLength];

    [encoder dispatchThreadgroupsWithIndirectBuffer:indirectArgsBuffer
                               indirectBufferOffset:argsIndex*sizeof(MTLDispatchThreadgroupsIndirectArguments)
                              threadsPerThreadgroup:MTLSizeMake(SCAN_BLOCKSIZE, 1, 1)];

    [encoder endEncoding];

}

- (void) encodeScanIndirectTo:(id<MTLCommandBuffer>)buffer
                        input:(id<MTLBuffer>)inputBuf
                       output:(id<MTLBuffer>)outputBuf
                       length:(id<MTLBuffer>)lengthBuf;
{
    auto encoder = [buffer computeCommandEncoder];
    [encoder setComputePipelineState:threadgroupsPipeline];
    [encoder setBuffer:lengthBuf offset:0 atIndex:ScanBufferIndexLength];
    [encoder setBuffer:indirectArgsBuffer offset:0 atIndex:ScanBufferIndexIndirectArguments];
    [encoder setBuffer:lengthsBuffer offset:0 atIndex:ScanBufferIndexLengths];
    [encoder dispatchThreadgroups:MTLSizeMake(1, 1, 1) threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
    [encoder endEncoding];

    [self encodeScanIndirectLevelTo:buffer input:inputBuf output:outputBuf aux:auxBuffer argsIndex:0];
    [self encodeScanIndirectLevelTo:buffer input:auxBuffer output:auxScanBuffer aux:aux2Buffer argsIndex:1];
    [self encodeScanIndirectLevelTo:buffer input:aux2Buffer output:aux2ScanBuffer aux:aux3Buffer argsIndex:2];

    [self encodeFixupIndirectTo:buffer input:auxScanBuffer aux:aux2ScanBuffer argsIndex:1];
    [self encodeFixupIndirectTo:buffer input:outputBuf aux:auxScanBuffer argsIndex:0];

}

@end
