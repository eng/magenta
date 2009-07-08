#!/usr/bin/env ruby -wKU
require 'rubygems'
gem 'net-ssh', '>=2.0.11'
require 'optparse'

magenta_root = File.expand_path(File.dirname(__FILE__))

options = {}

$LOAD_PATH.unshift(File.join(magenta_root, 'lib'))

require 'log'
require 'actions'
require 'deploy'

Log.level :info

begin
  
opts = OptionParser.new do |opts|
  opts.banner = "Usage: magenta.rb action [options]"

  opts.separator "action must be one of: deploy, rollback, or check."
  opts.separator "    deploy:    deploys a fresh clone of your repository."
  opts.separator "    rollback:  rolls back your deploy to the previous clone (1 time only)."
  opts.separator "    check:     just display configuration information."
  opts.separator ""
  opts.separator "Finds magenta.yml or config/magenta.yml from the current directory (or use -c option)."
  opts.separator ""
  opts.separator "In addition to/instead of magenta.yml, you can use these switches:"

  opts.on("-s", "--server SERVERNAME", "Specify server IP or name") do |s|
    options['server'] = s
  end
  
  opts.on("-r", "--repository REPOSITORY_URL", "Specify full repository path.  Default is to look for a git repository in the current directory and use it to determine the remote origin.") do |r|
    options['repository'] = r
  end

  opts.on("-a", "--app-path APP_PATH", "Specify path to your Rails app. Default is to look for a Rails app in the current directory.") do |c|
    options['app'] = c
  end
  
  opts.on("-c", "--config CONFIG_PATH", "Specify path to magenta.yml.  Default is to look in the current directory or a config/ subdirectory.") do |c|
    options['config'] = c
  end
  
  opts.on("-e", "--environment ENVIRONMENT", "Specify the environment section to read in magenta.yml. Default is the top-level values, or a production section if one exists.") do |e|
    options['environment'] = e
  end
    
  opts.on("-u", "--user USERNAME", "Specify SSH username (must have ssh key on client and server).  Default is to use the currently-logged in user.") do |u|
    options['user'] = u
  end
  
  opts.on("-d", "--deploy-to ROOT_DIR", "Specify deployment root directory tree on server. Required if not specified in magenta.yml.") do |d|
    options['deploy_to'] = d
  end
  
  opts.on("--skip-migrations", "Do not run pending migrations after updating the server. Default is to always run any pending migrations.") do
    options['skip-migrations'] = true
  end
  
  opts.on("--dry-run", "Dry run - just pretend to execute, don't really do anything.") do
    options['handler'] = DryRunServer
    Log.level :debug
  end
  
  opts.on("-q", "--quiet", "Run quietly (warnings only).") do
    Log.level :warn
  end

  opts.on("-v", "--verbose", "Run verbosely") do
    Log.level :debug
  end
end

opts.parse!

rescue => e
  puts e.message
  exit
end

action = ARGV.first

if action
  action = action.downcase
  raise "You must specify deploy, rollback, or check" unless ['deploy', 'rollback', 'check'].include?(action)
  send "#{action}_action", options 
else
  puts opts.help
end
