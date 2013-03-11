# -*- encoding: utf-8 -*-
require File.expand_path('../lib/gamer/version', __FILE__)

Gem::Specification.new do |spec|
	{
		:name => 'gamer',
		:version => Gamer::VERSION,
		:summary => 'Game server scanner',
		:description => 'Gamer scans game servers and retrieves associated information like player names, scores, etc.',
		:license => 'MIT',
		:author => 'floze',
		:homepage => 'http://www.floze.org',
		:files => Dir['LICENSE.txt', 'README.md', 'lib/**/*'],
		:require_paths => ['lib']
	}.each{ |property, value| spec.send("#{ property }=", value)}
end