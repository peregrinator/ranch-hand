module RanchHand
  class Logger
    def self.info(msg)
      logger.info(msg)
    end

    def self.logger
      @@logger ||= ::Logger.new(STDOUT)
    end
  end
end
