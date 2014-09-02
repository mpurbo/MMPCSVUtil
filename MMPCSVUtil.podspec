Pod::Spec.new do |s|
  s.name             = "MMPCSVUtil"
  s.version          = "0.0.1"
  s.summary          = "Utility for parsing and writing comma-separated values (CSV) files"
  s.description      = <<-DESC
                       Utility for parsing and writing comma-separated values (CSV) files. 

                       Features:
                       * Supports CSV and TSV.
                       DESC
  s.homepage         = "https://github.com/mpurbo/MMPCSVUtil"
  s.license          = 'MIT'
  s.author           = { "Mamad Purbo" => "m.purbo@gmail.com" }
  s.source           = { :git => "https://github.com/mpurbo/MMPCSVUtil.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/purubo'

  s.platform         = :ios
  s.source_files     = 'Classes'
  s.framework        = 'CoreData'
  s.requires_arc     = true  
end
