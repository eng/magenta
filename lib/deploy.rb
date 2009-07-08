require 'app'
require 'executors'
    
class Deploy
  
  attr_reader :app
  attr_reader :options
  
  def initialize(app, options)
    @app = app
    @options = app.config.merge(options)
    @options['handler'] ||= (@options['server'] ? SSH_Server : LocalServer)
    @options['server'] ||= 'localhost'
  end

  def dump_options
    Log.info "-" * 30
    Log.info "Will use this configuration:" do
      options.each do |k, v|
        Log.info "#{k}: #{v}" unless k == 'handler'
      end
    end
    Log.info "-" * 30
  end
  
  def deploy_path(*args)
    @deploy_path ||= @options['deploy_to']
    return @deploy_path unless args.any?
    File.join(@deploy_path, args)
  end
  
  def repository
    @options['repository']
  end
  
  def test
    Log.info "Testing" do
      dump_options
      on_server do
        setup_directory_tree
      end
    end
  end
  
  def test_mkdir
    execute_on_server "mkdir -p ~/sandbox/magenta-test"
  end
  
  def deploy!
    Log.info "Starting deployment" do
      Log.info "This is a DRY RUN.  Nothing will really happen." if @options['handler'] == DryRunServer
      dump_options

      raise "Server name not configured!" unless @options['server']
      raise "Deployment directory not configured!" unless deploy_path
      raise "Repository not configured!" unless repository

      on_server do
        setup_directory_tree
        create_new_release
        run_migrations
        update_links
        restart_app
      end
    end
  end
  
  def whoami
    execute_on_server "whoami"
  end
  
  def on_server
    @options['handler'].start(options) do |ssh|
      @ssh = ssh
      yield 
    end
  end
  
  def execute_on_server(cmd, opts = {})
    opts[:raise_errors] = true if opts[:raise_errors].nil?
    
    @ssh.exec!(cmd) do |ch, stream, data|
      if stream == :stderr
        Log.warn "SERVER #{opts[:raise_errors] ? 'ERROR' : 'WARNING'}: #{data}"
        raise ServerError.new(data) if opts[:raise_errors]
      else
        Log.debug data
      end
    end
  end
  
  def rails_env
    options['server'] != 'localhost' ? 'production' : 'development'
  end
  
  def run_migrations
    return if options['skip-migrations']
    
    Log.info "running migrations" do
      execute_on_server "cd #{@release_path}; rake db:migrate RAILS_ENV=#{rails_env}"
    end
  end
  
  def restart_app
    Log.info "restarting the application" do
      execute_on_server "touch #{current_path('tmp', 'restart.txt')}"
    end
  end
  
  def setup_directory_tree
    Log.info "setting up directory structure" do
      ['releases', 'shared', 'shared/log'].each do |dirname|
        execute_on_server "mkdir -p #{File.join(deploy_path,dirname)}"
      end
    end
  end
  
  def create_new_release
    Log.info "cloning new release from repository" do
      timestamp_name = Time.now.strftime("%Y%m%d%H%M%S")
      @release_path = deploy_path('releases', timestamp_name)
      Log.debug "Creating new clone into: #{@release_path}"
      execute_on_server "git clone #{repository} #{@release_path}"
      Log.debug "Cleaning up .git data"
      execute_on_server "rm -rf #{@release_path}/.git"
    end
    
  end
  
  def shared_path(*args)
    @shared_path ||= deploy_path('shared')
    return @shared_path unless args.any?
    File.join(@shared_path, args)
  end
  
  def current_path(*args)
    @current_path ||= File.join(deploy_path, 'current')
    return @current_path unless args.any?
    File.join(@current_path, args)
  end
  
  def release_path(*args)
    return @release_path unless args.any?
    File.join(@release_path, args)
  end
  
  def update_links
    Log.info "updating symlinks" do
      point_to_shared_links
      point_current_at_release_path
    end
  end
  def point_to_shared_links
    Log.debug "creating symlink for database.yml"
    execute_on_server "ln -s #{shared_path('config', 'database.yml')} #{release_path('config', 'database.yml')}", :raise_errors => false
    Log.debug "creating symlink for log directory"
    execute_on_server "rm -rf #{release_path('log')}; ln -s #{shared_path('log')} #{release_path('log')}", :raise_errors => false
  end
  
  def point_current_at_release_path
    Log.debug "updating symlink for the current release"
    execute_on_server "rm -f #{current_path}; ln -s #{release_path} #{current_path}"
  end
end