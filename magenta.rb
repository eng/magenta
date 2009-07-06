#!/usr/bin/env ruby -wKU
require 'rubygems'
gem 'net-ssh', '>=2.0.11'
# gem 'net-scp', '>=1.0.2'

require 'optparse'

magenta_root = File.dirname(__FILE__)
Dir[File.join(magenta_root, 'lib/**/*.rb')].each { |f| require f }

Log.level :info

def rollback_action(options)
  puts "Null reference exception (LMAO!)"
end

def test_action(options)
  begin
    Log.info "Magenta starting up..."
    app = App.new(options)
    d = Deploy.new(app, options)
    d.test
    Log.info "\nMagenta finished succesfully."  

  rescue ServerError => se
    Log.warn "*** Yikes! #{se}"
    Log.warn "Magenta cancelled."
    
  rescue => e
    Log.warn "*** Yikes! #{e}"
    Log.warn "Backtrace ---------"
    Log.warn e.backtrace.join("\n")
    Log.warn "-------------------"
    
  end
end


def check_action(options)
  Log.info "Magenta starting up..."
  app = App.new(options)
  Deploy.new(app, options).dump_options
end

def deploy_action(options)
    
  begin
    app = App.new(options)
    d = Deploy.new(app, options)
    d.deploy!
  
    Log.info "\nMagenta finished succesfully."

    rescue ServerError => se
      Log.warn "*** Yikes! #{se}"
      Log.warn "Magenta cancelled."
      
    rescue => e
      Log.warn "*** Yikes! #{e}"
      Log.warn "Backtrace ---------"
      Log.warn e.backtrace.join("\n")
      Log.warn "-------------------"
  end
end

options = {}

begin
  
OptionParser.new do |opts|
  opts.banner = "Usage: magenta.rb action [options]"

  opts.separator "action must be 'deploy', 'rollback', or 'check'"
  opts.separator "    deploy:    deploys a fresh clone of your repository."
  opts.separator "    rollback:  rolls back your deploy to the previous clone (1 time only)."
  opts.separator "    check:     displays the configuration but doesn't deploy."
  opts.separator ""
  opts.separator "Finds magenta.yml or config/magenta.yml from the current directory (or use -c option)."
  opts.separator ""
  opts.separator "Override the values in magenta.yml with these switches:"

  opts.on("-s", "--server SERVERNAME", "Specify server IP or name") do |s|
    options['server'] = s
  end
  
  opts.on("-r", "--repository REPOSITORY_URL", "Specify full repository path") do |r|
    options['repository'] = r
  end

  opts.on("-a", "--app-path APP_PATH", "Specify path to your Rails app") do |c|
    options['app'] = c
  end
  
  opts.on("-c", "--config CONFIG_PATH", "Specify path to magenta.yml") do |c|
    options['config'] = c
  end
  
  opts.on("-e", "--environment ENVIRONMENT", "Specify the environment section to read in magenta.yml") do |e|
    options['environment'] = e
  end
    
  opts.on("-u", "--user USERNAME", "Specify SSH username (must have ssh key on client and server)") do |u|
    options['user'] = u
  end
  
  opts.on("-d", "--deploy-to ROOT_DIR", "Specify deployment root directory tree on server") do |d|
    options['deploy_to'] = d
  end
  
  opts.on("--skip-migrations", "Do not run pending migrations.") do
    options['skip-migrations'] = true
  end
  
  opts.on("--dry-run", "Dry run - just pretend to execute, don't really do anything.") do
    options['handler'] = DryRunServer
  end
  
  opts.on("-q", "--quiet", "Run quietly (warnings only)") do
    Log.level :warn
  end

  opts.on("-v", "--verbose", "Run verbosely") do
    Log.level :debug
  end
end.parse!

rescue => e
  puts e.message
  exit
end

action = ARGV.first
puts action

raise "You must specify deploy, rollback, or check" unless ['deploy', 'rollback', 'check', 'test'].include?(action)

send "#{action}_action", options 

