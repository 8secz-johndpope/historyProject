#!/usr/bin/env ruby
require 'xcodeproj'
xcproj = Xcodeproj::Project.open("merchant-ios.xcodeproj")
xcproj.recreate_user_schemes
xcproj.save
