module Gamer
	class Server
		
		# QUERY_RECORD_INTERVAL = 6.hours
		
		attr_reader :instance, :host, :port, :protocol, :version, :name, :map, :mod, :location, :private, :maxplayers, :players, :raw_response
		
		def initialize instance, options = Hash.new
			@instance = instance
			@host = options[:host]
			@port = options[:port]
			@protocol = options[:protocol]
			@version = options[:version]
			@name = options[:name]
			@map = options[:map]
			@mod = options[:mod]
			@location = options[:location]
			@private = options[:private]
			@maxplayers = options[:maxplayers]
			@players = (options[:players] or Array.new)
			@raw_response = options[:raw_response]
		end
		
		def query options = Hash.new
			begin
				# do a master query if requested
				if options[:master]
					results = Array.new
					result_hash = { 'servers' => Array.new }
					# query master server with all available request strings
					for request_string in Gamer.commands_for(protocol)['masterqueries']
						if response = Gamer::Packet.new(:host => host, :port => port).request(request_string)
							results<<Gamer.constantize(protocol).new(:raw_response => response, :protocol => protocol).keys
						end
					end
					# merge results (i.e. { :host => ..., :port => ... }) of all requests
					for result in results
						result_hash['servers']+=result['servers'] if result and result['servers']
					end
					result_hash
				# otherwise do a regular query
				elsif request = Request.new(:host => host, :port => port, :protocol => protocol).get
					initialize instance, request.result
					self
				end
			rescue SocketError
				# TODO: log
			end
		end
		
		def instance_save
			record = instance.class.find_by_host_and_port(host, port)
			record ||= instance.class.new(:host => host, :port => port)
			if not responded?
				# increase server failure counter if unresponsive
				record.fails+=1
			elsif record.fails>0
				# reset server failure counter if responsive
				record.fails = 0
			end
			# create a query entry every QUERY_RECORD_INTERVAL
			build_queries_for record
			# build players/sessions
			build_players_for record
			# save record and return self
			record.save
			self
		end
		
		def servers
			res = query(:master => true)
			if res.is_a?(Hash) and not res.empty?
				servers = []
				for server in res['servers']
					servers<<Server.new(instance, {:host => server[:host], :port => server[:port], :protocol => protocol})
				end
				servers
			else
				# TODO: log
			end
		end
		
		def build_queries_for server_record
			if server_record.instance_queries.blank? or ((Time.now - server_record.instance_queries.last.created_at) > QUERY_RECORD_INTERVAL)
				server_record.instance_queries.build :raw_response => raw_response.to_yaml, :protocol => protocol
			elsif protocol # and ((Time.now - server_record.instance_queries.last.updated_at) > 1.minute)
				server_record.instance_queries.last.update_attributes :raw_response => raw_response.to_yaml, :protocol => protocol
			end
		end
		
		def build_players_for server_record
			return if not players or players.empty?
			for player in players
				player_record = server_record.instance_player_class.find_by_nick(player[:nick])
				if player_record.nil?
					server_record.instance_players.build :nick => player[:nick]
				else
					server_record.instance_sessions.build(
						player_record.class.to_s.underscore => player_record,
						server_record.class.to_s.underscore => server_record
					)
				end
			end
		end
		
		def response
			Gamer.constantize(protocol).new :raw_response => raw_response, :protocol => protocol
		end
		
		def responded?
			!raw_response.join.empty? if raw_response
		end
		
		def keys
			response.keys
		end
		
	end
end