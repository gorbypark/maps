require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

default_macos_mapbox_version = '~> 5.8.0'
rnmbgl_macos_version = $ReactNativeMapboxGLMACOSVersion || ENV["REACT_NATIVE_MAPBOX_MAPBOX_MACOS_VERSION"] || default_macos_mapbox_version
if ENV.has_key?("REACT_NATIVE_MAPBOX_MAPBOX_IOS_VERSION")
  puts "REACT_NATIVE_MAPBOX_MAPBOX_MACOS_VERSION env is deprecated please use `$ReactNativeMapboxGLMACOSVersion = \"#{rnmbgl_macos_version}\"`"
end

Pod::Spec.new do |s|
  s.name		= "react-native-mapbox-gl"
  s.summary		= "React Native Component for Mapbox GL"
  s.version		= package['version']
  s.authors		= { "Nick Italiano" => "ni6@njit.edu" }
  s.homepage    	= "https://github.com/@react-native-mapbox-gl/maps#readme"
  s.source      	= { :git => "https://github.com/@react-native-mapbox-gl/maps.git" }
  s.license     	= "MIT"
  s.platform    	= :ios, "8.0"

  s.dependency 'Mapbox-macOS-SDK', rnmbgl_macos_version
  s.dependency 'React-Core'
  s.dependency 'React'

  s.subspec 'DynamicLibrary' do |sp|
    sp.source_files	= "macos/RCTMGL/**/*.{h,m}"
  end

  if ENV["REACT_NATIVE_MAPBOX_GL_USE_FRAMEWORKS"]
    s.default_subspecs= ['DynamicLibrary']
  else
    s.subspec 'StaticLibraryFixer' do |sp|
      s.dependency '@react-native-mapbox-gl-mapbox-static', rnmbgl_macos_version
    end

    s.default_subspecs= ['DynamicLibrary', 'StaticLibraryFixer']
  end
end
