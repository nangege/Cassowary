# Cassowary
<a href="https://travis-ci.org/https://travis-ci.org/nangege/Cassowary"><img src="https://travis-ci.org/nangege/Cassowary.svg?branch=master"></a>
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![](https://img.shields.io/badge/iOS-8.0%2B-lightgrey.svg)]()
[![Swift 4.0](https://img.shields.io/badge/Swift-4.2-orange.svg)]()

Cassowary is a swift implement of  constraint solving algorithm [Cassowary](https://constraints.cs.washington.edu/cassowary/) which  forms the core of the OS X and iOS Autolayout . This project is start from a direct port of [rhea](https://github.com/Nocte-/rhea),but after that ,a lot of optimization has been added to make it performent better.
### Requirements
- iOS 8.0+
- Swift 4.2
- Xcode 10
### Installation

- Carthage  `github "https://github.com/nangege/Cassowary" "master"`
- Manually  -  just drag this project file to your workspace

Then add Cassowary to Linked Frameworks and Libraries

```swift
import Cassowary
```

### Usage
```swift
let v1 = Variable(),v2 = Variable, v3 = Variable()
let solver = SimplexSolver()
try? solver.add(v1 + v2 == 10)
try? solver.add(v1 - v2 == 2)
solver.solve()
print(solver.valueFor(v1)).  // 6
print(solver.valueFor(v2)).  // 4
```


### Lisence

The MIT License (MIT)

