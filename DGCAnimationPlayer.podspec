#
# Be sure to run `pod lib lint DGCAnimationPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DGCAnimationPlayer'
  s.version          = '0.1.0'
  s.summary          = 'A short description of DGCAnimationPlayer.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Mg/DGCAnimationPlayer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mg' => 'mg@mg.com' }
  s.source           = { :git => 'https://github.com/mg/DGCAnimationPlayer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  # s.source_files = 'DGCAnimationPlayer/Classes/**/*'
  s.source_files = 'DGCAnimationPlayer/Classes/**/*.{h,swift,m,mm}'
  
  # s.resource_bundles = {
  #   'DGCAnimationPlayer' => ['DGCAnimationPlayer/Assets/*.png']
  # }

  s.subspec 'LibRes' do |ss|
      ss.source_files = 'DGCAnimationPlayer/LibRes/include/*.h'
      # 隐藏头文件
      ss.private_header_files = [
        'DGCAnimationPlayer/LibRes/include/*.h'
      ]
      ss.vendored_libraries = 'DGCAnimationPlayer/LibRes/*.a'
  end
  
  s.subspec 'QGVAPlayer' do |ss|
      ss.source_files = 'DGCAnimationPlayer/QGVAPlayer/**/*'
  end

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'SVGAPlayer' # SVGAPlayer是本地库 需要在Podfile 先导入
  s.dependency 'MGNetWork' # MGNetwork是本地库 需要在Podfile 先导入
  s.dependency 'DGCLog' # YYEVA是本地库 需要在Podfile 先导入
  s.dependency 'Kingfisher', '~> 7.11.0'
  s.frameworks = 'AVFAudio'
  s.dependency 'MGFileHandle'
  s.dependency 'YYEVA', '~>1.1.32'
  s.dependency 'ZFPlayer'
  s.dependency 'ZFPlayer/AVPlayer'
end
