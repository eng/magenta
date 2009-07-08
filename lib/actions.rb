require 'exceptions'

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
