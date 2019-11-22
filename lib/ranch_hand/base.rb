module RanchHand
  class Base
    def self.setup
      RanchHand::Logger.info("setting up ranch-hand")
      FileUtils.mkdir_p(RanchHand::RANCH_HAND_HOME)
      File.new(RanchHand::STORE_FILE, 'w+', 0640)
      RanchHand::Logger.info("complete")
    end

    def self.init
      RanchHand::Logger.info("initializing ranch-hand for project")
      RanchHand::Config.create
      RanchHand::Logger.info("initialization complete")
    end
  end
end