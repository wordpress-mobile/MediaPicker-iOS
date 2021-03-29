Pod::Spec.new do |s|
  s.name          = "WPMediaPicker"
  s.version       = "1.7.2"

  s.summary       = "WPMediaPicker is an iOS controller that allows capture and picking of media assets."
  s.description   = <<-DESC
                    WPMediaPicker is an iOS controller that allows capture and picking of media assets.
                    It allows:
                    * Multiple selection of media.
                    * Capture of new media while selecting
                  DESC

  s.homepage      = "https://github.com/wordpress-mobile/MediaPicker-iOS"
  s.screenshots   = "https://raw.githubusercontent.com/wordpress-mobile/WPMediaPicker/trunk/screenshots_1.jpg"
  s.license       = { :type => 'GPLv2', :file => 'LICENSE' }
  s.author        = { "The WordPress Mobile Team" => "mobile@wordpress.org" }

  s.platform      = :ios, '11.0'
  s.swift_version = '5.0'

  s.source        = { :git => "https://github.com/wordpress-mobile/MediaPicker-iOS.git", :tag => s.version.to_s }
  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'WPMediaPicker' => ['Pod/Assets/*.png']
  }

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.private_header_files = 'Pod/Classes/WPDateTimeHelpers.h', 'Pod/Classes/WPImageExporter.h', 'Pod/Classes/UIViewController+MediaAdditions.h'
  s.frameworks = 'UIKit', 'Photos', 'AVFoundation', 'ImageIO'
end
