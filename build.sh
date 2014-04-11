#!/bin/bash

gem uninstall mystic; gem build mystic.gemspec; gem install mystic-*.gem;
