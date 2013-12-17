require 'logger'

# Logs to many devices, each of which may have an individual
# level and device.
#
# Acts in compliance with other configuration options from ruby's
# default Logger class.
#
# Author:: Stephen Wattam <http://stephenwattam.com>
# License:: Beerware
#
class MultiLog < Logger

  # Version, for convenience.
  VERSION  = '0.1.0a'

  # Default log level set to Logger::UNKNOWN
  DEFAULT_LEVEL = Logger::UNKNOWN

  # Create a simple log object with one log level and one device
  # 
  # The 'logdevs' argument takes the same values as specified in #configure_logs
  #
  def initialize(logdevs = {}, progname = nil, shift_age = 0, shift_size = 1048576)
    super(nil, shift_age, shift_size)
    @progname     = progname
    @shift_age    = shift_age
    @shift_size   = shift_size
    @lowest_level = DEFAULT_LEVEL
    configure_logs(logdevs)
  end

  # Set all logging devices as per the hash provided.
  # Will remove all current logs in the process.
  #
  # name :: Default: :default :: The name of the log, used when identifying it or removing it later
  # dev  :: Default: STDOUT :: The device to be used.  Should be an IO and will be closed on calling #close
  # level :: Default: The value of MultiLog.DEFAULT_LEVEL :: A log level as per ruby's Logger class or a string representing it.
  # shift_age :: Default: The value of @shift_age :: As per ruby's Logger
  # shift_size :: Default: The value of @shift_size :: As per ruby's Logger
  #
  def configure_logs(logdevs = {})
    # Remove all exsiting logs
    @logdevs.each{ |name, ld| remove_log(name) } if @logdevs

    # Parse logdevs hash options
    @logdevs      = {}
    logdevs       = [logdevs] if logdevs.is_a? Hash

    # If the user provides a device then set up a single log as :log
    unless logdevs.is_a? Array then
      @logdevs[:default]    = {:dev => logdevs, :level => DEFAULT_LEVEL}
      @lowest_level         = @logdevs[:default][:level]
      return
    end

    # If the user provides a hash, check each arg
    logdevs.each do |ld|
      name        = ld[:name]         ||= :default
      dev         = ld[:dev]          ||= $stdout
      level       = ld[:level]        ||= DEFAULT_LEVEL
      shift_age   = ld[:shift_age]    ||= @shift_age
      shift_size  = ld[:shift_size]   ||= @shift_size
      level       = MultiLog.string_to_level(level) unless level.is_a? Fixnum 

      # Add to the name deely.
      add_log(name, dev, level, shift_age, shift_size)
    end
  end

  # Add a log to the list of existing logs, without removing others
  #
  # name :: The name of the log
  # destination:: A device to log to
  # level :: As per ruby's Logger class
  # shift_age :: As per ruby's Logger class
  # shift_size :: As per ruby's Logger class
  #
  def add_log(name, destination, level, shift_age = 0, shift_size = 1048576)
    dev = LogDevice.new(destination, :shift_age => shift_age, :shift_size => shift_size)

    @logdevs[name] = {:dev => dev, :level => level}
    @lowest_level = level if (not @lowest_level) or level < @lowest_level
  end

  # Stop logging to one of the logs
  def remove_log(name)
    if(@logdevs[name])
      # Back up old level
      old_level = @logdevs[name][:level]

      # Remove
      @logdevs.delete(name)

      # Update lowest level if we need to
      @lowest_level = @logdevs.values.map{|x| x[:level] }.min if old_level == @lowest_level
    end
  end

  # Print a summary of log output devices to the log, at such a level
  # that all logs see it.
  def summarise
    add(@lowest_level, "Summary of logs:")
    if(@logdevs.length > 0)
      c = 0
      @logdevs.each{|name, ld|
        msg = " (#{c+=1}/#{@logdevs.length}) #{name} (level: #{MultiLog.level_to_string(ld[:level])}, device: fd=#{ld[:dev].dev.fileno}#{ld[:dev].dev.tty? ? " TTY" : ""}#{ld[:dev].filename ? " filename=#{ld[:dev].filename}" : ""})"
        add(@lowest_level,  msg)
      } 
    else
      add(@lowest_level, " *** No logs!") # Amusingly, this can never output
    end
  end

  # Set the log level of one of the logs to a given Logger level.
  def set_level(name, level=nil)
    # Default
    unless level then
      level = name
      name  = nil 
    end

    # Look up the level if the user provided a :symbol or "string"
    level = MultiLog.string_to_level(level.to_s) unless level.is_a? Fixnum

    if name
      # Set a specific one
      raise "No log by the name '#{name}'" unless @logdevs[name]
      @logdevs[name][:level] = level
    else
      # Set them all by default 
      @logdevs.each{|name, logdev| logdev[:level] = level }
    end
  end

  # Returns the log level of a log
  def get_level(name = nil)
    name = :default unless name
    return nil unless @logdevs[name]
    return @logdevs[name][:level]
  end

  # Overrides the basic internal add in Logger
  def add(severity, message = nil, progname = nil, &block)
    severity ||= UNKNOWN

    # give up if no logdevs or if too low a severity
    return true if severity < @lowest_level or (not @logdevs.values.map{ |ld| ld[:dev].nil? }.include?(false))

    # Set progname to nil unless it is explicitly specified
    progname ||= @progname
    if message.nil?
      if block_given?
        message   = yield
      else
        message   = progname
        progname  = @progname
      end
    end

    # Sync time across the logs and output only if above the log level for that device
    msg = format_message(format_severity(severity), Time.now, progname, message)
    @logdevs.each do |name, ld|
      ld[:dev].write(msg) unless ld[:dev].nil? && ld[:level] <= severity
    end
    return true
  end

  # Convert a log level to a string.
  #
  # Used in the output summary
  def self.level_to_string(lvl) 
    labels = %w(DEBUG INFO WARN ERROR FATAL)
    return labels[lvl] || "UNKNOWN"
  end

  # Convert a string to a logger level number.
  def self.string_to_level(str)
    labels = %w(DEBUG INFO WARN ERROR FATAL)
    return labels.index(str.to_s.upcase) || Logger::UNKNOWN
  end

  # Close the log and all associated devices.
  def close
    @logdevs.each do |name, ld|
      ld[:dev].close
    end
  end
end

