# cmake-xcodebuild

(WIP)
A CMake toolchain file helping to build fat-binary for apple platforms.

## Usage

You can customize the build using three variables:

- `XCODEBUILD_PLATFORM`: (Required) Select the target platform: `iOS`, `iOSSimulator`
  `macOS`, `tvOS`, `tvOSSimulator`, `watchOS` or `watchOSSimulator`
- `XCODEBUILD_PLATFORM_VERSION`: (Optional) The version of the SDK to use. Otherwise cmake will
   try to detect the last one
- `BITCODE_ENABLED`: (Optional) Generate bitcode or not

## Simple usage

```
cmake .. -DCMAKE_TOOLCHAIN_FILE=cmake/xcodebuild.cmake -DXCODEBUILD_PLATFORM=iOS
```
