module Gamer
	
	def self.included base
		base.send :extend, GamerServer::ClassMethods
	end
	
	module GamerServer
		
		module ClassMethods
			
			def acts_as_game_server options = Hash.new
				send :include, InstanceMethods
				has_many options[:queries]
				has_many options[:players], :through => options[:sessions]
				has_many options[:sessions]
				
				define_method 'instance_queries' do
					self.send options[:queries]
				end
				
				define_method 'instance_players' do
					self.send options[:players]
				end
				
				define_method 'instance_sessions' do
					self.send options[:sessions]
				end
				
				define_method 'instance_player_class' do
					options[:players].to_s.classify.constantize
				end
				
			end
		end
		
		module InstanceMethods
			
			def query
				gamer_server.query
			end
			
			def query!
				gamer_server.query.instance_save
			end
			
			def keys
				gamer_server.keys
			end
			
			def protocol
				if q = last_query
					@_protocol ||= q.protocol
				end
				@_protocol
			end
			
			def protocol= str
				@_protocol ||= str
			end
			
			def last_query
				@_last_query ||= instance_queries.last
			end
			
			def last_raw_response
				@_last_raw_response ||= YAML.load(last_query.raw_response) if last_query
			end
			
			def servers
				gamer_server.servers
			end
			
			private
			
			def gamer_server
				@_game_server ||= Gamer::Server.new(
					self,
					{
						:host => self.host,
						:port => self.port,
						:protocol => self.protocol,
						:raw_response => self.last_raw_response
					}
				)
				@_game_server
			end
			
		end
		
	end
	
end

# roll
if Object.const_defined?('ActiveRecord')
  ActiveRecord::Base.send :include, Gamer
end