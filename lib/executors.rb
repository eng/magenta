require 'net/ssh'

class SSH_Server
  def self.start(options)
    server, user = options['server'], options['user']
    Log.debug "Logging into #{server}"
    Net::SSH.start(server, user) { |ssh| yield ssh }
    Log.debug "Logged out of #{server}"
  end
end

class DryRunServer
  def self.start(*args)
    yield new
  end
  
  def exec!(cmd)
    Log.debug "executing: #{cmd}"
  end
end

class LocalServer
  def self.start(*args)
    yield new
  end
  
  def exec!(cmd)
    Log.debug "executing: #{cmd}"
    `#{cmd}`
  end
end

