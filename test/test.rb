#!/usr/bin/env ruby


require 'multilog'


logdevs = []
logdevs << {name: :default,
            device: STDOUT,
            level: 'INFO'
           }
logdevs << {name: :default2,
            device: STDOUT,
            level: 'INFO'
           }
logdevs << {name: :default3,
            device: STDOUT,
            level: 'INFO'
           }



log = MultiLog.new(logdevs)

# Apply nicer log output format
log.formatter = proc do |severity, datetime, progname, msg|
  "#{severity.to_s[0]} #{progname} [#{datetime.strftime('%y-%m-%d %H:%M:%S')}] #{msg}\n"
end

log.summarise

log.info "TEST"


