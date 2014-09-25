#!/usr/bin/env ruby

require "./root"

::DOTENV = Hash[Mystic.root.join(".env").each_line.map { |l| l.strip.split "=", 2 }] rescue {}