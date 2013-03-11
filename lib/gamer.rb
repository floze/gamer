#	Requirements:
#
#	gameserver model (:servers)
#		host:string
#		port:integer
#		fails.integer
#
#	gameserver_query model (:queries)
#		gameserver:references
#		raw_response:text
#		protocol:string
#
#	gameserver_player model (:players)
#		nick:string
#
#	gameserver_session model (:sessions)
#		gameserver:references
#		player:references
#
#	to set it up call like this in an initializer:
#
#	Gamer.load(
#			:servers => :gameservers,
#			:queries => :gameserver_queries,
#			:sessions => :gameserver_sessions
#			:players => :gameserver_players,
#		)

require 'gamer/acts_as_game_server'
require 'gamer/acts_as_game_server_player'
require 'gamer/acts_as_game_server_query'
require 'gamer/acts_as_game_server_session'

require 'gamer/server'
require 'gamer/packet'
require 'gamer/request'
require 'gamer/response'

require 'yaml'

require 'gamer/games/quake3_response'
require 'gamer/games/callofduty4_response'


module Gamer
	
	class GamerError < StandardError
	end
	
	class NotConfigured < Exception
	end
	
	class<<self
		attr_accessor :request_strings
	end
	
	def self.request_strings
		@request_strings or raise GamerError.new('Unable to load strings from request_strings.yml; call Gamer.load_request_strings_yaml in an initializer.')
	end
	
	def self.commands_for protocol
		return unless protocol
		cmnds = self.request_strings[protocol]
		self.raise_unhandled_protocol_exception(protocol) unless cmnds
		cmnds
	end
	
	def self.raise_unhandled_protocol_exception protocol
		raise NotConfigured.new("There are no commands specified for this game in request_strings.yml: #{ protocol ? protocol : 'unknown protocol' }")
	end
	
	def self.configuration= hash
		self.request_strings = hash
	end
	
	def self.load options = Hash.new
		options[:servers].to_s.classify.constantize.acts_as_game_server options
		options[:queries].to_s.classify.constantize.acts_as_game_server_query options
		options[:players].to_s.classify.constantize.acts_as_game_server_player options
		options[:sessions].to_s.classify.constantize.acts_as_game_server_session options
		self.load_request_strings_yaml
	end
	
	def self.load_request_strings_yaml
		config = YAML.load(File.read(File.join(File.dirname(__FILE__), 'gamer', 'request_strings.yml')))
		raise GamerError.new('Unable to load strings from request_strings.yml.') if config.nil?
		self.configuration = config
	end
	
	def self.constantize(str)
		return unless str
		protocol = self.request_strings[str]
		self.raise_unhandled_protocol_exception(str) unless protocol
		begin
			const_get("#{ str[0].upcase}#{str[1..-1] }Response")
		rescue NameError
			raise NotConfigured.new("There are no response parsers specified for this game: #{ str ? str : 'unknown' }")
		end
	end
	
	def self.run servers
		# TODO: log if list is empty
		return unless servers and !servers.empty?
		
		t = Time.now.to_f
		
		max_threads = 16
		max_servers_per_second = 6
		
		Thread.abort_on_exception = true
		
		threads = Array.new
		queue = SizedQueue.new(max_threads)
		result_servers = 0
		result_players = 0
		result_fails = 0
		if servers.size>max_threads
			slice_size = servers.size/(max_threads<=2 ? max_threads : max_threads-1)
		else
			slice_size = 1
		end
		
		# some threads to fill the queue
		servers.each_slice(slice_size) do |slice|
			threads<<Thread.new(slice) do
				for server in slice
					t_0 = Time.now.to_f
					queue<<server.query
					t_1 = Time.now.to_f
					# remember some stuff for the log
					if server.responded?
						result_servers+=1
						result_players+=server.players.size
					else
						result_fails+=1
					end
					# throttle if max_servers_per_second is set
					if max_servers_per_second and max_servers_per_second>0
						ratio = ((threads.size-1).to_f/max_servers_per_second.to_f)
						t_delta = t_1 - t_0
						if (ratio>t_delta)
							sleep(ratio-t_delta)
						end
					end
				end
			end
		end
		
		# one thread to process the queue #
		threads << Thread.new(queue) do
			servers.size.times do
				if server = queue.pop
					server.instance_save
				end
			end
		end
		
		threads.each { |thread|  thread.join }
		
		"#{ result_servers } of #{ servers.size } servers, #{ result_fails } fails, collected #{ result_players } players in #{ ((Time.now.to_f-t)*100).round.to_f/100 }s using #{ threads.size-1 } threads."
	end
	
end