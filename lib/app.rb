# server: jeffcohenonline.com # leave blank for local machine
# user:                       # leave blank for current user
# repository: ssh://jeffcohenonline.com/~/src/pw.git         # repo path
# deploy_to: ~/violet         # root folder for all deployed releases

# creates:
# deploy_to/releases/{releasename}
# deploy_to/shared/
#
# symlinks:
# deploy_to/current
# deploy_to/shared/log 

class App
  
  attr_accessor :path
  attr_accessor :config
  
  CONFIG_FILENAME = 'magenta.yml'
  
  def initialize(options)
    @app_path = File.expand_path(options['app'] || ('.'))
    @config_path = File.expand_path(options['config'] || find_config_file) rescue nil
    Log.info "Inspecting #{@app_path}"
    read_config(options)
    detect_config_from_app
  end
  
  def method_missing(m, *args)
    @config[m.to_s] 
  end

private

  def find_config_file
    @config_path = @app_path if File.exist?(File.join(@app_path, CONFIG_FILENAME))
    @config_path ||= File.join(@app_path, 'config') if File.exist?(File.join(@app_path, 'config', CONFIG_FILENAME))
  end
  def rails?
    File.exist?(File.join(@app_path, 'app')) && File.exist?(File.join(@path, 'script'))
  end
  
  def git?
    File.exist?(File.join(@app_path, '.git'))
  end
  
  def get_origin_repository
    if git?
      `cd #{@app_path}; git remote show origin` =~ /URL:\s*(.*)$/
      $1
    else
      nil
    end
  end
  
  def detect_config_from_app
    @config['repository'] ||= get_origin_repository
  end
  
  def read_config(options)
    if @config_path
      filename = File.join(@config_path, CONFIG_FILENAME)
      if File.exists?(filename)
        Log.info "Reading configuration file #{filename}" do
          @config = YAML.load_file(filename)
          environment = options['environment']
          @config = @config[environment] if @config.keys.include?(environment)
          set_defaults
          Log.info "Config: #{config.inspect}"
        end
      end
    else
      @config = {}
      set_defaults
    end
  end
  
  def set_defaults
    @config['user'] ||= `whoami`.chomp
  end
end