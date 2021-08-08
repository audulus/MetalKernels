# MetalKernels

![build status](https://github.com/Halfspace-LLC/MetalKernels/actions/workflows/build.yml/badge.svg)
<img src="https://img.shields.io/badge/SPM-5.3-blue.svg?style=flat"
     alt="Swift Package Manager (SPM) compatible" />

Useful kernels for parallel programming.

[`ScanKernel`](https://github.com/Halfspace-LLC/MetalKernels/blob/main/Sources/MetalKernels/include/ScanKernel.h) implements prefix sum for `uint32_t` values.

[`CompactKernel`](https://github.com/Halfspace-LLC/MetalKernels/blob/main/Sources/MetalKernels/include/CompactKernel.h) implements stream compaction for values of user-specified size.

[`RadixSortKernel`](https://github.com/Halfspace-LLC/MetalKernels/blob/main/Sources/MetalKernels/include/RadixSortKernel.h) implements radix sort for `uint32_t` values.
