module Gamer
	
	def self.included base
		base.send :extend, GamerServerQuery::ClassMethods
	end
	
	module GamerServerQuery
		
		module ClassMethods
			
			def acts_as_game_server_query options = Hash.new
				send :include, InstanceMethods
				belongs_to options[:servers].to_s.singularize.to_sym
			end
			
		end
		
		module InstanceMethods
			
			def keys options = Hash.new
				@_game_server_response ||= Gamer.constantize(self.protocol).new(
					{
						:raw_response => YAML.load(self.raw_response),
						:protocol => self.protocol
					}
				).keys
			end
			
		end
		
	end
	
end

# roll
if Object.const_defined?('ActiveRecord')
  ActiveRecord::Base.send :include, Gamer
end