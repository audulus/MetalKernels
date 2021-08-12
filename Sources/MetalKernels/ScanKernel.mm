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
    
    id<MTLComputePipelineState> scanPipeline;
    id<MTLComputePipelineState> fixupPipeline;
}

@end

@implementation ScanKernel

- (instancetype)init:(id<MTLDevice>)device
{
    self = [super init];
    if (self) {
        
        auxBuffer = [device newBufferWithLength:(1024*1024*10) options:MTLResourceStorageModeShared];
        auxScanBuffer = [device newBufferWithLength:(1024*1024*10) options:MTLResourceStorageModeShared];
        aux2Buffer = [device newBufferWithLength:(1024*1024*2) options:MTLResourceStorageModeShared];
        aux2ScanBuffer = [device newBufferWithLength:(1024*1024*2) options:MTLResourceStorageModeShared];
        aux3Buffer = [device newBufferWithLength:(1024) options:MTLResourceStorageModeShared];
        
        auto lib = GetMetalLibrary(device);
        scanPipeline = [self makeComputePipeline:@"prefixSum" library:lib device:device];
        fixupPipeline = [self makeComputePipeline:@"prefixFixup" library:lib device:device];
        
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

- (id<MTLBuffer>) getAux
{
    return auxBuffer;
}

- (id<MTLBuffer>) getAux2
{
    return aux2Buffer;
}

@end
