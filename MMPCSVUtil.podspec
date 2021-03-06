Pod::Spec.new do |s|
  s.name             = "MMPCSVUtil"
  s.version          = "0.1.2"
  s.summary          = "Utility for parsing comma-separated values (CSV) files with blocks and functional programming idioms"
  s.description      = <<-DESC
                       Utility for parsing comma-separated values (CSV) files with blocks and functional programming idioms. 

                       Features:
                       * Supports CSV or other user specified delimiter.
                       * Blocks for interacting with the parser.
                       * Functional programming idioms (filter, map, etc.)
                       DESC
  s.homepage         = "https://github.com/mpurbo/MMPCSVUtil"
  s.license          = 'MIT'
  s.author           = { "Mamad Purbo" => "m.purbo@gmail.com" }
  s.source           = { :git => "https://github.com/mpurbo/MMPCSVUtil.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/purubo'

  s.ios.deployment_target = "6.0"
  s.osx.deployment_target = "10.7"

  s.source_files     = 'Classes'
  s.requires_arc     = true  
end
