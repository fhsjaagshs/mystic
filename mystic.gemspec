Gem::Specification.new do |s|
  s.name         = "mystic"
  s.version      = "0.2.0"
  s.summary      = "Pooled PG singleton instance."
  s.description  = s.summary + " Focus more on writing SQL than dealing with a finnicky ORM. It powers the Pawky backend."
  s.authors      = ["Nathaniel Symer"]
  s.email        = "nate@natesymer.com"
  s.homepage     = "https://github.com/ivytap/mystic"
  s.license      = "MIT"
  s.files        = Dir.glob("{bin,lib,ext}/**/*") + ["LICENSE"]
  s.require_path = "lib"
  s.extensions   = ["ext/mystic/extconf.rb"]
  s.executables  = Dir.glob("bin/**/*").map{ |path| path.split("/",2).last }
	
  s.add_dependency 'access_stack', "~> 0"
end