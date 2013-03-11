module Gamer
	class Response
		
		attr_reader :packet, :raw_response, :protocol, :commands
		
		def initialize options = Hash.new
			@packet = options[:packet]
			@protocol = packet ? packet.protocol : options[:protocol]
			@raw_response = options[:raw_response]
			@commands = Gamer.commands_for(protocol)
		end
		
		def result
			{
				:host => packet.host,
				:port => packet.port,
				:protocol => packet.protocol
			}
		end
		
		def raw_response
			@raw_response ||= pull
		end
		
		def server
			Server.new result
		end
		
		def keys
			results = Array.new
			result_hash = Hash.new
			if raw_response.respond_to?(:each)
				for response in raw_response do
					results<<parse(response.force_encoding('ascii-8bit'))
				end
			else
				results<<parse(raw_response.force_encoding('ascii-8bit'))
			end
			for result in results do
				result_hash.merge!(result) if result
			end
			result_hash
		end
		
		def valid?
			!keys.empty?
		end
		
		private
		
		def pull response_strings = Array.new
			for query in commands['statusqueries']
				response_strings<<packet.request(query)
			end
			response_strings
		end
		
		def parse response
		end
		
	end
end