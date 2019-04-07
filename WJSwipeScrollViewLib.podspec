#
# Be sure to run `pod lib lint WJSwipeScrollViewLib.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WJSwipeScrollViewLib'
  s.version          = '0.1.1'
  s.summary          = 'WJSwipeScrollViewLib'

  s.description      = <<-DESC
TODO: ScrollView嵌套ScrolloView解决方案.实现原理：http://blog.csdn.net/glt_code/article/details/78576628,当前库只为方便自己使用,如有需要请联系原作者
                       DESC

  s.homepage         = 'https://github.com/allumos/WJSwipeScrollViewLib'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'amuryy@hotmail.com' => 'allumos@hotmail.com' }
  s.source           = { :git => 'https://github.com/allumos/WJSwipeScrollViewLib.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'Example/WJSwipeScrollViewLib/Lib/**/*'

end
