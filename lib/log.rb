class Log
  
  @@level = :debug
  @@indent = 0
  
  def self.level(level)
    @@level = level
  end
  
  def self.warn(msg)
    puts "#{'   ' * @@indent}#{msg}"
  end
  
  def self.debug(msg)
    if block_given?
      debug msg
      @@indent += 1
      yield
      @@indent -= 1
    else
      puts "#{'   ' * @@indent}#{msg}" if @@level == :debug
    end
  end
  
  def self.info(msg)
    if block_given?
      info msg
      @@indent += 1
      yield
      @@indent -= 1
      # info "finished: #{msg}"
    else
      puts "#{'   ' * @@indent}#{msg}" if @@level == :info || @@level == :debug
    end
  end

end