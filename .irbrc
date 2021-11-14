begin
  require "rubygems"
  require "pry"
rescue LoadError # rubocop:disable Lint/SuppressedException
end

if defined?(Pry)
  Pry.start
  exit
end
