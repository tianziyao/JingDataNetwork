#
# Be sure to run `pod lib lint JingDataNetwork.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JingDataNetwork'
  s.version          = '0.4.0'
  s.summary          = '网络请求+解析为任意模型+请求顺序控制'

  s.homepage         = 'https://github.com/tianziyao/JingDataNetwork'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tianziyao' => 'tianziyao@jingdata.com' }
  s.source           = { :git => 'https://github.com/tianziyao/JingDataNetwork.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.source_files = 'JingDataNetwork/Classes/**/*'
  s.dependency 'Moya', '~> 11.0'
  s.dependency 'ObjectMapper', '~> 3.3'
  s.dependency 'RxSwift',    '~> 4.0'
  s.dependency 'RxCocoa',    '~> 4.0'
  s.dependency 'SwiftyJSON',    '~> 4.0'

  # s.resource_bundles = {
  #   'JingDataNetwork' => ['JingDataNetwork/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
end
