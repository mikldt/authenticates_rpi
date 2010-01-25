# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{authenticates_rpi}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael DiTore"]
  s.date = %q{2010-01-24}
  s.description = %q{Rails plugin to manage CAS, Authentication, and LDAP name info}
  s.email = %q{mikldt@gmail.com}
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    ".gitignore",
     "MIT-LICENSE",
     "README",
     "Rakefile",
     "VERSION",
     "app/controllers/sessions_controller.rb",
     "app/views/sessions/show.html.erb",
     "app/views/sessions/sudo.html.erb",
     "authenticates_rpi.gemspec",
     "config/routes.rb",
     "init.rb",
     "install.rb",
     "lib/authenticates_rpi.rb",
     "tasks/authenticates_rpi_tasks.rake",
     "test/authenticates_rpi_test.rb",
     "test/test_helper.rb",
     "uninstall.rb"
  ]
  s.homepage = %q{http://github.com/mikldt/authenticates_rpi}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{CAS Authentication and Authorization on Rails!}
  s.test_files = [
    "test/test_helper.rb",
     "test/authenticates_rpi_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

