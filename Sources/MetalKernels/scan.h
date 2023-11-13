//  Copyright © Audulus LLC. Distributed under the MIT License.

#pragma once

enum ScanBufferIndex {
    ScanBufferIndexInput,
    ScanBufferIndexOutput,
    ScanBufferIndexAux,
    ScanBufferIndexLength,
    ScanBufferIndexZeroff,
    ScanBufferIndexIndirectArguments,
    ScanBufferIndexLengths,
};

#define SCAN_BLOCKSIZE        512
