Pod::Spec.new do |s|
  s.name         = "PEAppTransaction-Logger"
  s.version      = "1.0.0"
  s.license      = "MIT"
  s.summary      = "A library for logging application transactions to be persisted to a remote store."
  s.author       = { "Paul Evans" => "evansp2@gmail.com" }
  s.homepage     = "https://github.org/evanspa/#{s.name}"
  s.source       = { :git => "https://github.com/evanspa/#{s.name}.git", :tag => "#{s.name}-v#{s.version}" }
  s.platform     = :ios, '8.1'
  s.source_files = '**/*.{h,m}'
  s.public_header_files = '**/*.h'
  s.exclude_files = "**/*Tests/*.*"
  s.requires_arc = true
  s.dependency 'PEObjc-Commons'
  s.dependency 'PEHateoas-Client'
  s.dependency 'CocoaLumberjack', '~> 1.9'
end
