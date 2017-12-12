# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def shared
    pod 'RxSwift', "~> 4.0.0"
    pod "RxCocoa"
    pod "SwiftLint"
    pod 'SteviaLayout', "~> 4.0"
    pod 'IGListKit', '~> 3.0'
    pod "Timepiece"
    pod "PromiseKit", "~> 4.4", subspecs: ['CorePromise', 'CoreLocation']
    pod 'DefaultsKit'
    pod 'BartyCrouch'
    pod 'Fabric'
    pod 'Crashlytics'
end

target 'iOS Application' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SmartNetworkung
  shared
  
  pod 'Siren'
  
  target 'iOS Unit Tests' do
      inherit! :search_paths
      # Pods for testing
      pod 'Quick'
      pod 'Nimble'
  end

end

target 'iOS Today Widget' do
    use_frameworks!
    
    shared
end
