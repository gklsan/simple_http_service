
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "simple_http_service/version"

Gem::Specification.new do |spec|
  spec.name          = "simple_http_service"
  spec.version       = SimpleHttpService::VERSION
  spec.authors       = ["Gokul (gklsan)"]
  spec.email         = ["pgokulmca@gmail.com"]
  spec.summary       = 'SimpleHttpService is a simple Ruby library to make HTTP requests with customizable options for headers, timeouts, and retries. It provides a convenient way to create and send HTTP requests using a clean and simple interface.'
  spec.description   = 'SimpleHttpService is a simple Ruby library to make HTTP requests with customizable options for headers, timeouts, and retries. It provides a convenient way to create and send HTTP requests using a clean and simple interface.'
  spec.homepage      = "https://github.com/gklsan/simple_http_service"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata = {
      'homepage_uri' => spec.homepage,
      'source_code_uri' => "https://github.com/gklsan/simple_http_service",
      'changelog_uri' => "https://github.com/gklsan/simple_http_service/releases",
      'bug_tracker_uri' => "https://github.com/gklsan/simple_http_service/issues",
      'documentation_uri'  => "https://rubydoc.info/github/gklsan/simple_http_service"
    }
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "net-http", "~> 0.4.1"
  spec.add_development_dependency "bundler", "~> 2.5.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
