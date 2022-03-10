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

    def self.install_ohmyzsh
      RanchHand::Logger.info("installing ranch-hand Oh My Zsh shortcuts")

      unless ENV['ZSH_CUSTOM'] || ENV['ZSH']
        RanchHand::Logger.warn("Could not find $ZSH_CUSTOM or $ZSH in your environment, can not install shortcuts")
        return
      end

      zsh_custom_dir = ENV['ZSH_CUSTOM'] || File.join(ENV['ZSH'], 'custom')

      zsh_plugin_dir = File.join(zsh_custom_dir, 'plugins', 'ranch-hand')
      FileUtils.mkdir_p(zsh_plugin_dir)

      current_path = File.expand_path(File.dirname(__FILE__))
      gem_plugin_path = File.join(current_path, '..', '..', 'files', 'ranch-hand.plugin.zsh')

      FileUtils.cp(gem_plugin_path, zsh_plugin_dir)

      RanchHand::Logger.info("installation complete")
      RanchHand::Logger.info("Don't forget to add 'ranch-hand' to your plugins in ~/.zshrc -- e.g. plugins=(ranch-hand) -- and then 'source ~/.zshrc'")
    end

    def self.update_config
      RanchHand::Logger.info("updating ranch-hand config for project")
      RanchHand::Config.update
      RanchHand::Logger.info("update complete")
    end
  end
end
