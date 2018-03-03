Pod::Spec.new do |s|

  s.name         = "SPScrollPageView"

  s.version      = "0.0.1"

  s.summary      = "Help some common horizontal scroll pages to switch more smooth & easy"

  s.description  = <<-DESC
       Help some common horizontal scroll pages to switch more smooth & easy.让横向切换的页面多一种丝滑切换的理由。
                   DESC

  s.homepage     = "https://github.com/Tr2e/SPScrollPageView"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = { "Tr2e" => "tr2e@sina.com" }

  s.platform     = :ios,'8.0'

  s.source       = { :git => "https://github.com/Tr2e/SPScrollPageView.git", :tag => s.version }

  s.source_files = "SPScrollPageView/*.{h,m}"

  s.framework    = 'UIKit'

  s.requires_arc = true
  
end