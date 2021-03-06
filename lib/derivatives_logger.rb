class DerivativesLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    "#{msg}\n"
  end
end

derivative_log_file = File.open(Rails.root.join('log', 'derivatives.log'), 'a')
derivative_log_file.sync = true  # flush each log message immediately
DERIVATIVES_LOGGER = DerivativesLogger.new(derivative_log_file)
