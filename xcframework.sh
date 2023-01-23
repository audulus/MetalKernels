# Copyright © 2023 Halfspace LLC. All rights reserved.

# Script to build an xcframework from SculpturaCore so contractors can't access the core code.

# run mint install unsignedapps/swift-create-xcframework
# see https://github.com/unsignedapps/swift-create-xcframework

swift create-xcframework --no-debug-symbols
