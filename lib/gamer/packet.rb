require 'socket'
require 'timeout'

module Gamer
	class Packet
		
		attr_reader :host, :port, :protocol
		
		TIMEOUT = 1
		
		def initialize options = Hash.new
			@host = options[:host]
			@port = options[:port]
			@protocol = options[:protocol]
		end
		
		def request(str)
			buff = Array.new
			begin
				sock = send(str)
				begin
					packet = recv(sock)
					buff << packet
					# receive another packet if the last packet was large enough
				end while (packet and packet.length > 640)
			rescue IOError, SystemCallError
				# TODO: log
			ensure
				if sock
					sock.flush
					sock.close
				end
			end
			buff.join
		end
		
		private
		
		def send str
			Socket.do_not_reverse_lookup = true
			sock = UDPSocket.open
			sock.connect host, port
			sock.send str, 0
			sock
		end
		
		def recv sock
			data = nil
			if select([sock], nil, nil, TIMEOUT)
				begin
					timeout(TIMEOUT) do
						sock.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK) if defined? Fcntl::O_NONBLOCK
            data = sock.recvfrom_nonblock(2**16)
					end
				rescue Timeout::Error
					# TODO: log
				end
			end
			if data
				data = data[0]
			end
			data
		end
		
	end
end