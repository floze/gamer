module Gamer
	
	def self.included base
		base.send :extend, GamerServerSession::ClassMethods
	end
	
	module GamerServerSession
		
		module ClassMethods
			
			def acts_as_game_server_session options = Hash.new
				send(:include, InstanceMethods)
				belongs_to options[:servers].to_s.singularize.to_sym
				belongs_to options[:players].to_s.singularize.to_sym
			end
			
		end
		
		module InstanceMethods
		end
		
	end
	
end

# roll
if Object.const_defined?('ActiveRecord')
  ActiveRecord::Base.send(:include, Gamer)
end