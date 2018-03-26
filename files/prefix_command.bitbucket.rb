#!/usr/bin/env ruby
require 'json'
require 'yaml'

if STDIN.tty?
  puts 'This command is meant be launched by webhook'
else
  prefixes = YAML.load_file('/etc/puppet/r10k/r10k.yaml')

  json_data = JSON.parse(STDIN.read)
  #Bitbucket style payload
  reponame = json_data['repository']['name']
  projkey = json_data['repository']['project']['key']

  prefix = ""

  prefixes["sources"].each do |key,value|
    # Custom YAML properties in r10k.yaml to match the source with the commit/payload
    if reponame == value['repository_name'] and projkey == value['project_key'] then
      if value['prefix'] == true
        prefix = key
      elsif value['prefix'].is_a? String
        prefix = value['prefix']
      end
    end
  end

  puts prefix
end
