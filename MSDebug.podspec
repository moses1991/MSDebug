Pod::Spec.new do |s|
    s.name         = 'MSDebug'
    s.version      = '1.0'
    s.summary      = '一些常用Objective-C调试工具'
    s.homepage     = 'https://github.com/moses1991/MSDebug'
    s.license      = 'MIT'
    s.authors      = {'moses' => 'moses89757@gmail.com'}
    s.platform     = :ios, '9.0'
    s.source       = {:git => 'https://github.com/moses1991/MSDebug.git', :tag => s.version}
    s.source_files = 'MSDebug/**/*.{h,m}'
    s.resource     = 'MSDeubg/MSDebug.bundle'
    s.requires_arc = true
    s.dependency 'FMDB'
    s.dependency 'Masonry'
end
