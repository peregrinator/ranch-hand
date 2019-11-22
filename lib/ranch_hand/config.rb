module RanchHand
  class Config
    extend RanchHand::Commands

    def self.create
      save(generate_config)
      RanchHand::Logger.info("Config file saved to #{project_config_path}")
    end

    def self.load
      begin
        YAML.load_file(project_config_path)
      rescue Errno::ENOENT
        {}
      end
    end

    private

    def self.generate_config
      namespace = prompt.ask('Namespace:')
      group = prompt.ask('Use group command by default? (Y/n):')
      group = %w(n N).include?(group) ? false : true
      pod = prompt.ask('Pod name:')

      {
        group: group,
        namespace: namespace,
        pod: pod
      }
    end

    def self.save(config)
      # File.new(project_config_path, 'w+', 0640)

      File.open(project_config_path, 'w', 0640) do |f|
        f.write(config.to_yaml)
      end
    end

    def self.project_config_path
      File.join(Dir.pwd, ".ranch-hand")
    end
  end
end
