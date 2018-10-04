Pod::Spec.new do |s|

  s.name         = "SwiftCassowary"
  s.version      = "0.1-beta"
  s.summary      = "Swift implement of constraint solving algorithm"

  s.description  = <<-DESC  
                   Cassowary is a swift implement of constraint solving algorithm Cassowary which forms the core of the OS X and iOS Autolayout . 
                   * This library is heavily inspired by this c++ implement rhea
                   DESC

  s.homepage     = "https://github.com/nangege/Cassowary"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.authors            = { "TangNan" => "nangezao@foxmail.com" }

  s.swift_version = "4.2"

  s.ios.deployment_target = "8.0"
  s.module_name = "Cassowary"


  #s.source       = { :git => "git@github.com:nangege/Cassowary.git", :tag => s.version }
 s.source       = { :git => "https://github.com/nangege/Cassowary.git", :tag => '0.1-beta' }
  
  s.source_files  = ["Cassowary/Sources/*.swift", "Cassowary/Cassowary.h"]
  s.public_header_files = ["Cassowary/Cassowary.h"]
  

  s.requires_arc = true

end
