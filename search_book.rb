#!/usr/bin/env ruby
# encoding: utf-8
require 'json'
require 'open-uri'
require 'uri'
require './yolp'
require 'sinatra'

require 'dotenv/load'

cinii_appid = ENV['cinii_API_ID']
yahoo_appid = ENV['yahoo_API_ID']

get '/search_book' do
  erb :search_book
end

get '/book_result' do
  @info = [] 
  @book = params[:book]

  url = "https://ci.nii.ac.jp/books/opensearch/search?title=#{@book}&format=json&appid=#{cinii_appid}"

  response = URI.open(url).read
  json_data = JSON.parse(response)

  max_results = 20
  count = 0

  json_data['@graph'][0]['items'].each do |item|
    id = item['@id']
    id = id.split('/').last
    id = id.split('.').first
    title = item['title']
    puts "ID: #{id}, Title: #{title}"
    @info << { id: id, title: title }

    count += 1
    break if count >= max_results
  end

  erb :book_result
end

get '/search' do
  erb :search
end

get '/result' do
  @info = [] # Initialize as an array

  url = "https://ci.nii.ac.jp/ncid/#{params[:id]}.json"

  response = URI.open(url).read
  json_data = JSON.parse(response)

  max_results = 20
  count = 0

  json_data['@graph'][0]['bibo:owner'].each do |owner|
    address_url = owner['@id']
    address_url += '.json'

    response2 = URI.open(address_url).read
    json_data2 = JSON.parse(response2)

    library_name = json_data2['@graph'][0]['v:fn']
    library_address = json_data2['@graph'][0]['v:adr']['v:label']
    library_id = json_data2['@graph'][0]['@id'].split('/').last # Extracting the ID from the URL

    # Append information for each library to the array
    @info << { id: library_id, name: library_name, address: library_address }

    count += 1
    break if count >= max_results
  end

  erb :result
end

get '/map' do
  @address = params[:address]

  encoded_address = URI.encode_www_form_component(@address)

  idokedo_url = "https://map.yahooapis.jp/geocode/V1/geoCoder?appid=#{yahoo_appid}&output=json&query=#{encoded_address}"

  response3 = URI.open(idokedo_url).read
  json_data3 = JSON.parse(response3)

  coordinates = json_data3['Feature'][0]['Geometry']['Coordinates']
  bbox = json_data3['Feature'][0]['Geometry']['BoundingBox']

  coordinates = coordinates.split(',')
  bbox = bbox.split(/[,\s]+/)

  @latitude = coordinates[0]
  @longitude = coordinates[1]

  @bbox0 = bbox[0]
  @bbox1 = bbox[1]
  @bbox2 = bbox[2]
  @bbox3 = bbox[3]

  erb :map
end
