Pod::Spec.new do |s|
  s.name        = "StoryContent"
  s.version     = "0.4.1"
  s.license     = "MIT"
  s.homepage    = "https://breffi.ru/en/storyclm"
  s.author      = "Breffi LLC"
  s.summary     = "StoryContent is the module of Story platform"
  s.description	= "<<-DESC
                     Story— a digital-platform developed by BREFFI, allowing you to create interactive presentations with immediate feedback on the change in the customer perception of the brand and the representative’s activity.
                   DESC"
  s.source      = { :git => "https://github.com/storyclm/story-content-ios.git", :tag => s.version.to_s }

  s.source_files        = "StoryContent.framework/Headers/*.h"
  s.public_header_files = "StoryContent.framework/Headers/*.h"
  s.vendored_frameworks = "StoryContent.framework"

  s.ios.deployment_target	= "11.0"
  s.swift_version         	= "4.2"
  s.requires_arc          	= true

  s.dependency 'Alamofire', '4.8.1'
  s.dependency 'Kingfisher', '~> 5.6.0'
end
