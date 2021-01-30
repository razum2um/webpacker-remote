# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'webpacker-remote'
  spec.version       = '0.2.0'
  spec.authors       = ['Vlad Bokov']
  spec.email         = ['vlad@lunatic.cat']
  spec.license       = 'MIT'

  spec.summary       = 'Inject external webpack builds into Rails'
  spec.description   = 'Use your webpack builds independently'
  spec.homepage      = 'https://github.com/lunatic-cat/webpacker-remote'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/lunatic-cat/webpacker-remote'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency('webpacker', ENV.fetch('WEBPACKER_GEM_VERSION', '< 6'))

  spec.add_development_dependency('rspec', '~> 3.0')
  spec.add_development_dependency('simplecov', '~> 0.19')
end
