Pod::Spec.new do |s|
  s.name         = "Lift"
  s.version      = "2.3.0"
  s.summary      = "Working with JSON-like structures"
  s.description  = <<-DESC
                   Lift is a Swift library for generating and extracting values into and out of JSON-like structures.
                   DESC
  s.homepage     = "https://github.com/iZettle/Lift"
  s.license      = { type: "MIT", file: "LICENSE.md" }
  s.author       = { 'PayPal Inc.' => 'hello@izettle.com' }

  s.osx.deployment_target = "10.9"
  s.ios.deployment_target = "9.0"

  s.source       = { git: "https://github.com/iZettle/Lift.git", tag: s.version.to_s }
  s.source_files = "Lift/*.{swift}"
  s.swift_version = '5.0'
end
