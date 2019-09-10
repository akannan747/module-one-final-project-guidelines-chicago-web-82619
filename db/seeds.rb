# THIS IS WHERE WE GET API DATA

require 'rest-client'
require 'json'
require 'pry'
require_relative "../config/environment.rb"

API_KEY = "RGAPI-01b882fa-edbb-448f-88d8-4618268535aa"
REGION = 'na1'
#use fresh API key before presentation!!!!!!!

#return hash of all data for each champion
def get_champion_data(patch_number)
  response_string = RestClient.get("http://ddragon.leagueoflegends.com/cdn/#{patch_number}/data/en_US/champion.json")
  response_hash = JSON.parse(response_string)
  champion_data = response_hash["data"]
end

# TEST METHODS
def run
  #1st - Get a list of summoner names.
  #2nd - Get the accountId for the first summoner.
  #3rd - Get the matchIds for that accountId.
  names = get_summoner_names
  accountId = get_account_id(names[0])
  matchIds = get_match_ids(accountId)
  match_data = get_match_data(matchIds[0])
  create_match(match_data)
end

#returns a list of summoner names
def get_summoner_names
  # Make an API request for all summoners in a ranked division.
  response_string = RestClient.get("https://na1.api.riotgames.com/lol/league/v4/entries/RANKED_SOLO_5x5/SILVER/II?page=1&api_key=#{API_KEY}")
  summoner_data = JSON.parse(response_string)
  # For each summoner whose data is in summoner_data, return their name.
  summoner_names = summoner_data[0..0].map do |summoner| 
    summoner_name = summoner["summonerName"].gsub(" ", "%20").encode("ASCII", invalid: :replace, undef: :replace)
    #sleep(1)
  end
end

#Using the summoner name, create a Summoner
def create_summoner(summoner_name)
  Summoner.create(summoner_name)
end

#Using the summoner name, return single account id
def get_account_id(summoner_name)
  # Given the summoner's name, make an API request for account information.
  url = "https://#{REGION}.api.riotgames.com/lol/summoner/v4/summoners/by-name/#{summoner_name}?api_key=#{API_KEY}"
  response_string = RestClient.get(url)
  # The JSON object contains summoner account information. Return the accountId.
  summoner_account_info = JSON.parse(response_string)
  account_id = summoner_account_info["accountId"]
end

#returns an array of match ids given an account id
def get_match_ids(account_id)
  # Given a summoner's accountId, make an API request for their match history.
  url = "https://#{REGION}.api.riotgames.com/lol/match/v4/matchlists/by-account/#{account_id}?api_key=#{API_KEY}"
  response_string = RestClient.get(url)
  match_history = JSON.parse(response_string)
  match_ids = match_history["matches"].map {|match| match['gameId']}
end

#returns match data given a single match id
def get_match_data(match_id)
  # Given a matchId, make an API request for the match data.
  url = "https://#{REGION}.api.riotgames.com/lol/match/v4/matches/#{match_id}?api_key=#{API_KEY}"
  response_string = RestClient.get(url)
  match_data = JSON.parse(response_string)
end

#Given match data, creates a Match object for each player in the match.
def create_match(match_data)
  participants = match_data["participantIdentities"]
  for participant in participants do
    # Create a new Match object.
    match = Match.new
    # Set the Match's summoner_id field.
    summoner = create_summoner(name: participant["player"]["summonerName"])
    match.summoner_id = summoner.id
    # Set the Match's champion_id and win field.
    participant_data = match_data["participants"]
    current_summoner = participant_data.find do |data|
      data["participantId"] == participant["participantId"]
    end
    match.champion_id = current_summoner["championId"]
    match.win = current_summoner["stats"]["win"]
    # Set the Match's game_id field.
    match.game_id = match_data["gameId"]
    # Set the Match's ban field.
    binding.pry
  end

  #ban = match_data["teams"]["bans"]
end