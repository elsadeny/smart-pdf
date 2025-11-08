#!/usr/bin/env ruby

require 'xcodeproj'

# Path to the Xcode project
project_path = 'Runner.xcodeproj'

# Open the project
project = Xcodeproj::Project.open(project_path)

# Find the Runner target
target = project.targets.find { |t| t.name == 'Runner' }

if target.nil?
  puts "Error: Runner target not found"
  exit 1
end

# Clean up any existing spdfcore references
puts "Cleaning up existing spdfcore references..."

# Remove existing framework references
project.files.each do |file|
  if file.path && file.path.include?('spdfcore')
    puts "Removing existing reference: #{file.path}"
    file.remove_from_project
  end
end

# Remove existing build phases for spdfcore
target.build_phases.reject! do |phase|
  if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
    phase.name && (phase.name.include?('spdfcore') || phase.name.include?('Copy spdfcore'))
  else
    false
  end
end

puts "Adding spdfcore framework with proper embedding..."

# Create framework reference  
frameworks_group = project.main_group.find_subpath('Frameworks', true)
framework_path = 'Runner/Frameworks/spdfcore.framework'
framework_ref = frameworks_group.new_reference(framework_path)
framework_ref.source_tree = 'SOURCE_ROOT'

# Add to Link Binary With Libraries phase
target.frameworks_build_phase.add_file_reference(framework_ref)

# Find or create Embed Frameworks phase
embed_phase = target.build_phases.find do |phase|
  phase.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) &&
  phase.dst_subfolder_spec == '10' # Frameworks folder
end

if embed_phase.nil?
  embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed_phase.name = 'Embed Frameworks'
  embed_phase.dst_path = ''
  embed_phase.dst_subfolder_spec = '10' # Frameworks destination
  target.build_phases << embed_phase
end

# Add framework to embed phase
build_file = embed_phase.add_file_reference(framework_ref)
build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }

# Set framework search paths
target.build_configurations.each do |config|
  config.build_settings['FRAMEWORK_SEARCH_PATHS'] ||= []
  search_paths = config.build_settings['FRAMEWORK_SEARCH_PATHS']
  
  # Ensure it's an array
  search_paths = [search_paths] if search_paths.is_a?(String)
  search_paths ||= []
  
  # Add inherited first, then our framework path
  unless search_paths.include?('$(inherited)')
    search_paths.insert(0, '$(inherited)')
  end
  
  framework_search_path = '$(PROJECT_DIR)/Runner/Frameworks'
  unless search_paths.include?(framework_search_path)
    search_paths << framework_search_path
  end
  
  config.build_settings['FRAMEWORK_SEARCH_PATHS'] = search_paths
  
  # Ensure framework is properly linked
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] ||= []
  runpath_search_paths = config.build_settings['LD_RUNPATH_SEARCH_PATHS']
  runpath_search_paths = [runpath_search_paths] if runpath_search_paths.is_a?(String)
  runpath_search_paths ||= []
  
  unless runpath_search_paths.include?('$(inherited)')
    runpath_search_paths.insert(0, '$(inherited)')
  end
  
  framework_runpath = '@executable_path/Frameworks'
  unless runpath_search_paths.include?(framework_runpath)
    runpath_search_paths << framework_runpath
  end
  
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = runpath_search_paths
end

# Save the project
project.save
puts "✅ Successfully configured spdfcore framework for proper App Store distribution!"
puts "The framework will now be:"
puts "  - Linked during build time"
puts "  - Embedded in the app bundle"
puts "  - Code signed automatically"
puts "  - Ready for App Store submission"