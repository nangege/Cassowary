# Cassowary
<a href="https://travis-ci.org/https://travis-ci.org/nangege/Cassowary"><img src="https://travis-ci.org/nangege/Cassowary.svg?branch=master"></a>
[![Version](https://img.shields.io/cocoapods/v/SwiftCassowary.svg?style=flat)](http://cocoapods.org/pods/SwiftCassowary)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![](https://img.shields.io/badge/iOS-8.0%2B-lightgrey.svg)]()
[![Swift 4.0](https://img.shields.io/badge/Swift-4.2-orange.svg)]()

Cassowary is a swift implement of  constraint solving algorithm [Cassowary](https://constraints.cs.washington.edu/cassowary/) which  forms the core of the OS X and iOS Autolayout . This project is start from a direct port of [rhea](https://github.com/Nocte-/rhea),but after that ,a lot of optimization has been added to make it performent better.

## Requirements
- iOS 8.0+
- Swift 4.2
- Xcode 10

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org/) is a dependency manager for Cocoa projects. Install it with the following command:

`$ gem install cocoapods`

To integrate Cassowary into your Xcode project using CocoaPods, specify it to a target in your Podfile:

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
  # your other pod
  # ...
  pod 'SwiftCassowary'
end
```
Then, run the following command:

`$ pod install`

open the `{Project}.xcworkspace` instead of the `{Project}.xcodeproj` after you installed anything from CocoaPods.

For more information about how to use CocoaPods, [see this tutorial](http://www.raywenderlich.com/64546/introduction-to-cocoapods-2).

### Carthage


[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager for Cocoa application. To install the carthage tool, you can use [Homebrew](http://brew.sh).

```bash
$ brew update
$ brew install carthage
```

To integrate Panda into your Xcode project using Carthage, specify it in your `Cartfile`:

```bash
github "https://github.com/nangege/Cassowary" "master"
```

Then, run the following command to build the Panda framework:

```bash
$ carthage update
```

At last, you need to set up your Xcode project manually to add the Cassowary framework.

On your application targets’ “General” settings tab, in the “Linked Frameworks and Libraries” section, drag and drop each framework you want to use from the Carthage/Build folder on disk.

On your application targets’ “Build Phases” settings tab, click the “+” icon and choose “New Run Script Phase”. Create a Run Script with the following content:

```bash
/usr/local/bin/carthage copy-frameworks
```

and add the paths to the frameworks you want to use under “Input Files”:

```bash
$(SRCROOT)/Carthage/Build/iOS/Cassowary.framework
```

For more information about how to use Carthage, please see its [project page](https://github.com/Carthage/Carthage).


## Usage
```swift
import Cassowary

let v1 = Variable(),v2 = Variable, v3 = Variable()
let solver = SimplexSolver()
try? solver.add(v1 + v2 == 10)
try? solver.add(v1 - v2 == 2)
solver.solve()
print(solver.valueFor(v1)).  // 6
print(solver.valueFor(v2)).  // 4
```


## Lisence

The MIT License (MIT)

