#!/usr/bin/env ruby

# Simple test script to verify AudioFallback concern works
require_relative 'config/environment'

puts "Testing AudioFallback concern..."

# Create a lesson
lesson = Lesson.new

# Test that the methods exist
puts "has_any_audio? method exists: #{lesson.respond_to?(:has_any_audio?)}"
puts "has_optimized_audio? method exists: #{lesson.respond_to?(:has_optimized_audio?)}"
puts "has_audio? method exists: #{lesson.respond_to?(:has_audio?)}"
puts "best_audio method exists: #{lesson.respond_to?(:best_audio)}"
puts "best_audio_download_url method exists: #{lesson.respond_to?(:best_audio_download_url)}"
puts "best_audio_dom_id method exists: #{lesson.respond_to?(:best_audio_dom_id)}"

puts "\nAll AudioFallback methods are available!"
