Gem::Specification.new do |s|
  s.name         = "mystic"
  s.version      = "0.0.1"
  s.summary      = "Lightweight migrations + SQL execution"
  s.description  = "Database management/access gem. Supports adapters, migrations, and a singleton to make SQL queries."
  s.authors      = ["Nathaniel Symer"]
  s.email        = "nate@ivytap.com"
  s.homepage     = "https://github.com/ivytap/mystic"
  s.license      = "MIT"
  s.files        = Dir.glob("{bin,lib}/**/*") + ["LICENSE"]
  s.require_path = "lib"
  s.executables  = Dir.glob("bin/**/*").map{ |path| path.split("/",2).last }
  s.add_dependency 'densify', '~> 0.0', '>= 0.0.1'
  s.add_dependency 'connection_pool', '~> 2.0', '>= 2.0.0'
end