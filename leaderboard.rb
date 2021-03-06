#!/usr/bin/env ruby

require 'sinatra'
require 'mechanize'
require 'json'

set :environment, :production

config = JSON.parse(File.open("config.json").read())

discourse_api_key = config["discourse_api_key"]
coinhive_secret = config["coinhive_secret"]


before do
  @result = File.open("page.html")
end

agent = Mechanize.new()

def getBadgeIDs(username, agent)
	response = JSON.parse(agent.get("https://0x00sec.org/user-badges/" + username + ".json").body())
	return response["badges"].map{|b| b["id"]}
end

set :port, 8080
ip = "0.0.0.0"
api_get = ""
data = []

Thread.new{
	loop {
		a = agent.get("https://api.coin-hive.com/user/list?secret="+coinhive_secret).body()
		data = JSON.parse(a)
		api_get = JSON.generate(data["users"].sort {|a,b| a["total"] <=> b["total"]}.reverse)
		sleep 1
	}
}

Thread.new{
	loop {
		sleep 20
		puts "Doing check.."
		badge_boundaries = {"bronze"=>1000000, "silver"=>5000000, "gold"=>10000000, "insane"=>100000000, "god"=>1000000000}
		badge_id_lookup = {"bronze"=>117,"silver"=>118, "gold"=>119, "insane"=>120, "god"=>121}
		for user in data["users"]
			badge_check = {}
			if user["total"] >= 1000000
				puts "Checking " + user["name"]
				user_badges = getBadgeIDs(user["name"], agent)
				badge_boundaries.each do |total|
					badge_check[total[0]] = user["total"] >= total[1]
				end

				badge_check.each do |badge|
					current_badge_id = badge_id_lookup[badge[0]]
					if badge[1] and (!user_badges.include? current_badge_id)
						puts "Attempting to assign " + user["name"] + " " + badge[0] + " badge"
						sleep 10
						headers = {}
						params = {"api_key"=> discourse_api_key,
						"api_username"=>"system", "username"=>user["name"], "badge_id"=>current_badge_id, "reason"=>""}
						r = agent.post("https://0x00sec.org/user_badges.json", params, headers)
					end
				end

			end
		end
	}
}

get '/' do
	return @result
end

get '/data.json' do
	return api_get
end
