Gem::Specification.new do |spec|
  spec.name          = 'carpenter'
  spec.version       = '0.1.0'
  spec.authors       = 'Adam Leff'
  spec.email         = 'adamleff@chef.io'
  spec.summary       = 'Handy helper to manage compliance workshop environments'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/chef/compliance-workshop-environment'
  spec.license       = 'Apache-2.0'

  spec.files = %w{
    README.md Rakefile MAINTAINERS.toml MAINTAINERS.md LICENSE inspec.gemspec
    Gemfile CHANGELOG.md .rubocop.yml
  } + Dir.glob(
    '{bin,docs,examples,lib}/**/*', File::FNM_DOTMATCH
  ).reject { |f| File.directory?(f) }

  spec.executables   = %w{ carpenter }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.1'

  spec.add_dependency 'hashie'
  spec.add_dependency 'highline'
  spec.add_dependency 'mixlib-log'
  spec.add_dependency 'mixlib-shellout'
  spec.add_dependency 'mixlib-versioning'
  spec.add_dependency 'thor'

  spec.add_development_dependency 'pry'
end
