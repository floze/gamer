module Gamer
	class Quake3Response < Response
		
		def result
			result_hash = keys
			{
				:host =>packet.host,
				:port => packet.port,
				:protocol => packet.protocol,
				:version => result_hash['version'],
				:name => result_hash['hostname'] ? result_hash['hostname'] : result_hash['sv_hostname'],
				:map => result_hash['mapname'],
				:mod => result_hash['game'],
				:location => result_hash['location'],
				:private => result_hash['g_needpass'],
				:maxplayers => result_hash['sv_maxclients'],
				:players => result_hash['players'],
				:raw_response => raw_response
			}
		end
		
		private
		
		def parse response
			return unless response
			response = response.force_encoding('ascii-8bit')
			res = Hash.new
			# check if masterserver response
			if response[0..21]==commands['masterresponse'].force_encoding('ascii-8bit')
				res = { 'servers' => parse_master(response) }
			else
				for statusresponse in commands['statusresponses']
					# check if status response
					if response[0..17]==statusresponse.force_encoding('ascii-8bit')
						blocks = response.split("\n")
						status = blocks[1]
						players = blocks[2..-1]
						status_res = parse_status(status) if status
						players_res = parse_players(players) if players
						res = status_res.merge({ 'players' => players_res })
					# check if info response
					elsif response[0..15]==statusresponse.force_encoding('ascii-8bit')
						blocks = response.split("\n")
						info = blocks[1]
						res = parse_info(info) if info
					end
				end
			end
			res
		end
		
		def parse_master(str)
			servers = Array.new
			str.split('\\').each do |r|
				addr = Array.new
				r.each_byte do |b|
					addr<<b.to_s
				end
				(servers<<{ :host => addr[0..3].join('.'), :port => addr[-2].to_i*256+addr[-1].to_i }) if addr.size==6
			end
			servers
		end
		
		def parse_status(str)
			res = Hash.new
			status = str.split('\\')
			# check for odd size of the array, because we'll convert it to a hash
			unless (status.size % 2)==0
				if status.first==''
					status.delete status.first
					# convert to utf-8
					status = status.each{ |s| s.encode('utf-8', 'iso-8859-1') if s }
					res = Hash[*status]
				end
			end
			res
		end
		
		def parse_players array
			players = Array.new
			for item in array do
				info = item.split(' ')
				frags = info[0].encode('utf-8', 'iso-8859-1') if info[0]
				ping = info[1].encode('utf-8', 'iso-8859-1') if info[1]
				nick = item.split('"').last
				players<<{ :nick => (nick.encode('utf-8', 'iso-8859-1') if nick), :frags => frags, :ping => ping }
			end
			players
		end
		
		def parse_info str
			res = Hash.new
			status = str.split('\\')
			# check for odd size of the array, because we'll convert it to a hash
			unless (status.size % 2)==0
				if status.first==''
					status.delete(status.first)
					# convert to utf-8
					status = status.each{ |s| s.encode('utf-8', 'iso-8859-1') if s }
					res = Hash[*status]
				end
			end
			res
		end
		
	end
end