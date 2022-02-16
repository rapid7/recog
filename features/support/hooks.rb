require "cucumber/platform"

Before "@requires-ruby-platform-java" do
 skip_this_scenario unless Cucumber::JRUBY
end
  
Before "@unsupported-on-platform-java" do
 skip_this_scenario if Cucumber::JRUBY
end
