//  Copyright © 2021 Halfspace LLC. All rights reserved.

#include <metal_stdlib>
using namespace metal;
#include "split.h"

kernel void split_prep(device const uint* input [[ buffer(SplitBufferIndexInput) ]],
                       constant uint& bit       [[ buffer(SplitBufferIndexBit)   ]],
                       device uint* e           [[ buffer(SplitBufferIndexE)     ]],
                       constant uint& count     [[ buffer(SplitBufferIndexCount) ]],
                       uint tid                 [[ thread_position_in_grid       ]]) {

    if(tid >= count) {
        return;
    }

    e[tid] = (input[tid] & (1<<bit)) == 0;
}

kernel void split_scatter(device const uint* input [[ buffer(SplitBufferIndexInput)  ]],
                          device uint* output      [[ buffer(SplitBufferIndexOutput) ]],
                          constant uint& bit       [[ buffer(SplitBufferIndexBit)    ]],
                          device const uint* e     [[ buffer(SplitBufferIndexE)      ]],
                          device const uint* f     [[ buffer(SplitBufferIndexF)      ]],
                          constant uint& count     [[ buffer(SplitBufferIndexCount)  ]],
                          uint tid                 [[ thread_position_in_grid        ]])
{
    if(tid >= count) {
        return;
    }

    uint falses = e[count-1] + f[count-1];
    uint t = tid - f[tid] - falses;
    bool b = (input[tid] & (1<<bit)) != 0;
    uint d = b ? t : f[tid];

    output[d] = input[tid];
}
