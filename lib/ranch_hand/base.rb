module RanchHand
  class Base
    def self.setup
      RanchHand::Logger.info("setting up ranch-hand")
      FileUtils.mkdir_p(RanchHand::RANCH_HAND_HOME)
      File.new(RanchHand::STORE_FILE, 'w+', 0640)
      RanchHand::Logger.info("complete")
    end
  end
end