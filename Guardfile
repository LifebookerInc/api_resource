# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
  # Uncomment next line if Gemfile contain `gemspec' command
  # watch(/^.+\.gemspec/)
end

guard 'rspec', :version => 2, :cli => "--color --format nested --drb", :all_on_start => false, :all_after_pass => false do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^lib/api_resource/(.+)\.rb$})  {|m| "spec/lib/#{m[1]}_spec.rb"}
  watch('spec/spec_helper.rb')  { "spec/" }
end

guard 'spork' do
  watch('api_resource.gemspec')
  watch('Gemfile.lock')
  watch('spec/spec_helper.rb') { :rspec }
end