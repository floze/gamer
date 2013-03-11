module Gamer
	
	def self.included base
		base.send :extend, GamerServerPlayer::ClassMethods
	end
	
	module GamerServerPlayer
		
		module ClassMethods
			
			def acts_as_game_server_player options = Hash.new
				send :include, InstanceMethods
				has_many options[:servers], :through => options[:sessions]
				has_many options[:sessions]
			end
			
		end
		
		module InstanceMethods
		end
		
	end
	
end

# roll
if Object.const_defined?('ActiveRecord')
  ActiveRecord::Base.send :include, Gamer
end