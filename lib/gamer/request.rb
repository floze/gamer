module Gamer
	class Request
	
		attr_accessor :host, :port, :protocol
		
		def initialize options = Hash.new
			@host = options[:host]
			@port = options[:port]
			@protocol = options[:protocol]
		end
		
		def get
			Gamer.constantize(protocol).new(
				:packet => Packet.new(
						:host => host,
						:port => port,
						:protocol => protocol
					)
				)
		end
		
	end
end