#!/usr/bin/env ruby
# Usage:
#   ruby Scripts/xcp.rb add-files iPhoneSensors path/relative/to/iPhoneSensors/iPhoneSensors/App/foo.swift ...
#   ruby Scripts/xcp.rb add-target iPhoneSensorsTests
#   ruby Scripts/xcp.rb add-package https://github.com/groue/GRDB.swift 7.0.0 GRDB iPhoneSensors
require 'xcodeproj'

PROJ_PATH = File.expand_path('../iPhoneSensors/iPhoneSensors.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJ_PATH)
cmd = ARGV.shift

case cmd
when 'add-files'
  target_name = ARGV.shift
  target = project.targets.find { |t| t.name == target_name } or abort "no target #{target_name}"
  ARGV.each do |rel|
    abs = File.expand_path(File.join(File.dirname(PROJ_PATH), rel))
    abort "missing #{abs}" unless File.exist?(abs)
    parts = rel.split('/')
    subpath = File.join(parts[0..-2])
    group = project.main_group.find_subpath(subpath, true)
    group.set_source_tree('SOURCE_ROOT')
    group.path = subpath if group.path.nil?
    group.name = nil if group.name == subpath
    file_ref = group.files.find { |f| f.path == parts.last } || group.new_reference(parts.last)
    unless target.source_build_phase.files_references.include?(file_ref)
      target.source_build_phase.add_file_reference(file_ref)
    end
  end
when 'add-resource'
  target_name = ARGV.shift
  target = project.targets.find { |t| t.name == target_name } or abort "no target"
  ARGV.each do |rel|
    parts = rel.split('/')
    group = project.main_group.find_subpath(File.join(parts[0..-2]), true)
    group.set_source_tree('SOURCE_ROOT')
    fr = group.files.find { |f| f.path == parts.last } || group.new_reference(parts.last)
    target.resources_build_phase.add_file_reference(fr) rescue nil
  end
when 'add-package'
  url, version, product, target_name = ARGV
  target = project.targets.find { |t| t.name == target_name } or abort "no target"
  ref = project.root_object.package_references.find { |r| r.repositoryURL == url }
  unless ref
    ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
    ref.repositoryURL = url
    ref.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => version }
    project.root_object.package_references << ref
  end
  dep = target.package_product_dependencies.find { |d| d.product_name == product }
  unless dep
    dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dep.product_name = product
    dep.package = ref
    target.package_product_dependencies << dep
  end
  # Ensure the frameworks build phase has a PBXBuildFile whose product_ref is
  # the SPM product dependency (this is what tells the linker to link GRDB).
  unless target.frameworks_build_phase.files.any? { |bf| bf.product_ref == dep }
    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.product_ref = dep
    target.frameworks_build_phase.files << build_file
  end
when 'add-test-target'
  name = ARGV.shift
  abort "exists" if project.targets.any? { |t| t.name == name }
  target = project.new_target(:unit_test_bundle, name, :ios, '17.0')
  target.build_configurations.each do |bc|
    bc.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/iPhoneSensors.app/iPhoneSensors'
    bc.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
    bc.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "com.allsensors.#{name}"
    bc.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    bc.build_settings['SWIFT_VERSION'] = '5.0'
    bc.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    bc.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  end
  app = project.targets.find { |t| t.name == 'iPhoneSensors' }
  target.add_dependency(app)
else
  abort "unknown cmd: #{cmd}"
end

project.save
puts "ok: #{cmd}"
