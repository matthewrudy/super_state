# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{super_state}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matthew Rudy Jacobs"]
  s.date = %q{2011-03-15}
  s.email = %q{MatthewRudyJacobs@gmail.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["MIT-LICENSE", "Rakefile", "README", "test/common_states_test.rb", "test/super_state_test.rb", "test/test_helper.rb", "lib/super_state/common_states.rb", "lib/super_state.rb"]
  s.homepage = %q{http://github.com/matthewrudy/super_state}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Super Simple State Machine}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
