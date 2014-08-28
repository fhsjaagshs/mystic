Gem::Specification.new do |s|
  s.name         = "mystic"
  s.version      = "0.1.2"
  s.summary      = "Pooled PG singleton instance."
  s.description  = s.summary + " Focus more on writing SQL than dealing with a finnicky ORM. It powers the Pawky backend."
  s.authors      = ["Nathaniel Symer"]
  s.email        = "nate@natesymer.com"
  s.homepage     = "https://github.com/ivytap/mystic"
  s.license      = "MIT"
  s.files        = Dir.glob("{bin,lib}/**/*") + ["LICENSE"]
  s.require_path = "lib"
  s.executables  = Dir.glob("bin/**/*").map{ |path| path.split("/",2).last }
	
  s.add_dependency 'densify', "~> 0"
  s.add_dependency 'access_stack', "~> 0"
  s.add_dependency 'pg', '~> 0'
end