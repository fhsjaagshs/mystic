Gem::Specification.new do |s|
  s.name         = "mystic"
  s.version      = "0.1.0"
  s.summary      = "Pooled PG singleton instance. Focus more on writing SQL than dealing with a finnicky ORM."
  s.description  = "Database management/access gem. Supports adapters, migrations, and a singleton to make SQL queries."
  s.authors      = ["Nathaniel Symer"]
  s.email        = "nate@natesymer.com"
  s.homepage     = "https://github.com/ivytap/mystic"
  s.license      = "MIT"
  s.files        = Dir.glob("{bin,lib}/**/*") + ["LICENSE"]
  s.require_path = "lib"
  s.executables  = Dir.glob("bin/**/*").map{ |path| path.split("/",2).last }
	
  s.add_dependency 'densify', "~> 0"
  s.add_dependency 'access_stack', "~> 0"
end