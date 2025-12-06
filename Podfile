source 'https://cdn.cocoapods.org/'

inhibit_all_warnings!

install! 'cocoapods', :deterministic_uuids => false

abstract_target 'BasePods' do
	pod 'BRCLucene', '~> 1.0.0-beta1'

	target 'BRFullTextSearch' do
		platform :ios, '12.0'
	end

	target 'BRFullTextSearchTests' do
		platform :ios, '12.0'
	end

	target 'BRFullTextSearchMacOS' do
		platform :osx, '10.15'
	end
end

post_install do |installer|
  min_ios = '12.0'
  min_macos = '10.15'
  supported_platforms = 'iphoneos iphonesimulator macosx xros xrsimulator'
  targeted_device_family = '1,2,6,7'

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = min_ios
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = min_macos
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386 x86_64'
      config.build_settings['SUPPORTED_PLATFORMS'] = supported_platforms
      config.build_settings['SUPPORTS_MACCATALYST'] = 'YES'
      config.build_settings['TARGETED_DEVICE_FAMILY'] = targeted_device_family
    end
  end

  # Deduplicate conflicting headers in BRCLucene so the new build system is happy.
  preferred_headers = {
    'Scorer.h' => 'src/core/CLucene/search/Scorer.h',
    '_FastCharStream.h' => 'src/core/CLucene/util/_FastCharStream.h',
    'libstemmer.h' => 'src/contribs-lib/CLucene/snowball/include/libstemmer.h'
  }

  installer.pods_project.targets.each do |target|
    next unless target.name.start_with?('BRCLucene')
    seen = {}

    target.headers_build_phase.files.to_a.each do |build_file|
      file_path = build_file.file_ref.respond_to?(:path) ? build_file.file_ref.path : nil
      basename = File.basename(file_path) if file_path
      next unless basename && preferred_headers.key?(basename)

      if file_path != preferred_headers[basename] || seen[basename]
        target.headers_build_phase.remove_build_file(build_file)
      else
        seen[basename] = true
      end
    end
  end

  installer.pods_project.save
end
