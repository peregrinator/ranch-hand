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

    def self.update
      save(generate_config(load))
    end

    private

    def self.generate_config(current={})
      unless current.empty?
        puts "Current config:"
        pp current
        puts "A blank entry to the following prompts will keep the current config value."
      end

      namespace = prompt.ask('Namespace:')
      group = prompt.ask('Use group command by default? (Y/n):')
      pod = prompt.ask('Pod name:')
      prefix = prompt.ask('Command prefix (optional):')

      # set default value if there is no current or entered value
      if group.nil? && current[:group].nil?
        group = %w(n N).include?(group) ? false : true
      end

      # if command prefix is provided set prefer_ui to false
      # prefer_ui skips the #exec command line ui if set to true
      # this supports a base case where the prefix command is the
      # only command the user wants to run (eg. simple connection to the pod)
      if current[:prefer_ui]
        prefer_ui = nil
      elsif prefix || current[:command_prefix]
        prefer_ui = false
      else
        prefer_ui = true
      end

      current.merge({
        command_prefix: prefix,
        group: group,
        namespace: namespace,
        pod: pod,
        prefer_ui: prefer_ui
      }.compact)
    end

    def self.save(config)
      File.open(project_config_path, 'w', 0640) do |f|
        f.write(config.to_yaml)
      end
    end

    def self.project_config_path
      File.join(Dir.pwd, ".ranch-hand")
    end
  end
end
