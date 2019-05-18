Pod::Spec.new do |s|

  s.name         = "HJAsyncTcpCommunicator"
  s.version      = "2.0.2"
  s.summary      = "Asynchronous TCP communication module based on Hydra framework."
  s.homepage     = "https://github.com/P9SOFT/HJAsyncTcpCommunicator"
  s.license      = { :type => 'MIT' }
  s.author       = { "Tae Hyun Na" => "taehyun.na@gmail.com" }

  s.ios.deployment_target = '8.0'
  s.requires_arc = true

  s.source       = { :git => "https://github.com/P9SOFT/HJAsyncTcpCommunicator.git", :tag => "2.0.2" }
  s.source_files  = "Sources/*.{h,m}"
  s.public_header_files = "Sources/*.h"

  s.dependency 'Hydra'

end
