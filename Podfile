xcodeproj 'Example/CBRCloudKitConnection'

target 'CBRCloudKitConnection', :exclusive => true do
  pod "CBRCloudKitConnection", :path => "."

  if ENV["USER"] == "oliver"
    pod "CloudBridge", :path => "../CloudBridge"
  else
    pod "CloudBridge", :head
  end
end

target 'Tests', :exclusive => true do
  pod 'Expecta'
end
