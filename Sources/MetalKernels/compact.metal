//  Copyright © Audulus LLC. Distributed under the MIT License.

#include <metal_stdlib>
using namespace metal;

kernel void compact_prep(visible_function_table<bool(const device char*)> table,
                         device const char* input,
                         device uint* keep,
                         constant uint& size,
                         constant uint& count,
                         uint tid                 [[ thread_position_in_grid       ]]) {

    if(tid >= count) {
        return;
    }

    auto predicate = table[0];
    keep[tid] = predicate(input + size * tid);

}

kernel void compact_scatter(device const char* input,
                            constant uint& size,
                            constant uint& count,
                            device const uint* keep,
                            device const uint* dest,
                            device char* output,
                            uint tid                 [[ thread_position_in_grid       ]]) {

    if(tid >= count) {
        return;
    }

    if(keep[tid]) {
        for(uint i=0;i<size;++i) {
            output[dest[tid]*size + i] = input[tid*size + i];
        }
    }

}
