Pod::Spec.new do |s|
  s.name         = "SHOmniAuthFacebook"
  s.version      = "0.1.0"
  s.summary      = "Facebook Strategy for SHOmniAuth, uses SHAccountStore and SHRequest."

  s.description  = <<-DESC
                    A strategy for authenticating with Facebook via SHOmniAuth.
                    Uses SHAccountStore for store and SHRequest for signed requests.
                   DESC
  s.homepage     = "https://github.com/seivan/SHOmniAuthFacebook"

  s.license      = {:type => 'MIT' } 
  s.author       = { "Seivan Heidari" => "seivan.heidari@icloud.com" }
  
  s.source       = { :git => "https://github.com/seivan/SHOmniAuthFacebook.git", :tag => s.version.to_s}
  s.platform     = :ios, '5.0'

  s.source_files = 'SHOmniAuthFacebook/**/*.{h,m}'
  s.requires_arc = true
  s.frameworks   = 'Accounts', 'Social'

  s.dependency  'AFOAuth1Client',         '~> 0.2.0'
  s.dependency  'SHOmniAuth',             '~> 0.1.0'
end
