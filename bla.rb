require 'bundler'
Bundler.require

Gamer.load_request_strings_yaml

# bla = Gamer::Server.new(:host => '62.140.250.90', :port => 28972, :protocol => 'quake3')
# bla.query
# raise bla.map.inspect


# bla = Gamer::Request.new(:host => '188.40.68.69', :port => 28960, :protocol => 'quake3').get.server
# raise bla.inspect

# host = 'monster.idsoftware.com'
# port = 27950

host = 'cod4master.activision.com'
port = 20810

request = "\xFF\xFF\xFF\xFFgetservers full empty".force_encoding('ascii-8bit')
servers = Array.new
response = Gamer::Packet.new(:host => host, :port => port).request(request)
response.split('\\').each do |r|
	addr = Array.new
	r.each_byte do |b|
		addr<<b.to_s
	end
	(servers<<{ :host => addr[0..3].join('.'), :port => addr[-2].to_i*256+addr[-1].to_i }) if addr.size==6
end

# servers = servers[0..20]

puts "#{ servers.size } servers in list"

t = Time.now.to_f
max_threads = 16
max_servers_per_second = 8
threads = Array.new
result_s = 0
result_p = 0
bla = 0

servers.each_slice(servers.size/(max_threads<=2 ? max_threads : max_threads-1)) do |slice|
	threads << Thread.new(slice) do
		for s in slice
			server = Gamer::Server.new(nil, :host => s[:host], :port => s[:port], :protocol => 'quake3').query
			unless server.raw_response.join.empty?
				result_s = result_s+1
				result_p = result_p+server.players.size
				puts "got ##{ result_s }: #{ server.name } #{ server.host }:#{ server.port }"
			else
				bla = bla + 1
				puts "bla ##{ bla }: #{ server.host }:#{ server.port }"
			end
			
			# throttle requests:
			# sleep(max_threads/max_servers_per_second)
			
			str = STDIN
			if IO.select([str], nil, nil, max_threads/max_servers_per_second)
				blubb = str.read_nonblock(1)
			end
			if blubb
				puts "#{ result_s } of #{ servers.size } servers, #{ bla } bla, collected #{ result_p } players in #{ ((Time.now.to_f-t)*100).round.to_f/100 }s using #{ threads.size } threads."
				Thread.main.kill
			end
			
		end
	end
end

threads.each { |thread|  thread.join }

puts "#{ result_s } of #{ servers.size } servers, #{ bla } bla, collected #{ result_p } players in #{ ((Time.now.to_f-t)*100).round.to_f/100 }s using #{ threads.size } threads."