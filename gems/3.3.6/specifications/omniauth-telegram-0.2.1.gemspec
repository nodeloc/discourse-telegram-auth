# -*- encoding: utf-8 -*-
# stub: omniauth-telegram 0.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-telegram".freeze
  s.version = "0.2.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yuri Mikhaylov".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-04-10"
  s.description = "An OmniAuth strategy for Telegram".freeze
  s.email = ["me@yurijmi.ru".freeze]
  s.homepage = "https://github.com/yurijmi/omniauth-telegram".freeze
  s.rubygems_version = "3.1.6".freeze
  s.summary = "An OmniAuth strategy for Telegram".freeze

  s.installed_by_version = "3.5.22".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<omniauth>.freeze, [">= 1.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.16".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 10.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.0".freeze])
end
