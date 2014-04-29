#!/bin/bash

gem uninstall mystic
gem build mystic.gemspec
gem install --ignore-dependencies --local mystic-*.gem;
