module RanchHand
  class KubeCtl
    include RanchHand::Commands

    def exec(namespace, options={})
      if options[:remove]
        remove_command(namespace)
      elsif options[:repeat]
        repeat_command(namespace)
      elsif options[:command]
        pod = select_pod(namespace, options)
        run_command(namespace, pod, options[:command])
      else
        choose_command(namespace, options)
      end
    end

    def run_command(namespace, pod, cmd)
      system("rancher kubectl -n #{namespace} exec -it #{pod} -- #{cmd}")
    end

    def choose_command(namespace, options={})
      pod = select_pod(namespace, options)
      type, cmd = select_command(namespace, pod)
      
      run_command(namespace, pod, cmd)
    end

    def remove_command(namespace)
      pod = select_pod(namespace)
      type, cmd = select_command(namespace, pod, remove: true)

      storage_key = case type
      when :global
        "exec:commands:global"
      when :namespace
        "exec:commands:#{namespace}"
      when :pod
        "exec:commands:#{namespace}:#{pod_name(pod)}"
      end

      storage.set(storage_key, storage.get(storage_key) - Array(cmd))
    end

    def repeat_command(namespace)
      run_command(
        namespace,
        storage.get("exec:#{namespace}:latest:pod"),
        storage.get("exec:#{namespace}:latest:cmd")
      )
    end

    def select_pod(namespace, options={})
      pods = pods(namespace)

      if options[:filter]
        if options[:filter].start_with?('-')
          pods = pods.reject{|p| p.match?(/#{options[:filter][1..-1]}/)} 
        else
          pods = pods.select{|p| p.match?(/#{options[:filter]}/)} 
        end
      end
      prompt.error("No pods matching filter: '#{options[:filter]}'") and exit if pods.empty?

      if options[:group]
        pods = pods.group_by{|p| pod_name(p)}.map{|name, pods| pods.first}
      end

      pod = prompt.enum_select("Which pod?", pods, per_page: 10,
        default: pods.index(
          storage.get("exec:#{namespace}:latest:pod")
        ).to_i + 1
      )
      storage.set("exec:#{namespace}:latest:pod", pod)
      pod
    end

    def select_command(namespace, pod, options={})
      commands =  all_commands(namespace, pod, options)

      ask = options[:remove] ? 'Remove command:' : 'Run command:'
      type, cmd = prompt.enum_select(ask) do |menu|
        menu.default commands.collect{|k,v| v}.flatten.index(
            storage.get("exec:#{namespace}:latest:cmd")
          ).to_i + 1

        commands.each do |type, commands|
          commands.each do |cmd|
            menu.choice cmd, [type, cmd]
          end
        end
      end

      unless options[:remove]
        if cmd == "Add command"
          type, cmd = add_command(namespace, pod)
        elsif cmd == "Run once"
          type, cmd = nil, run_once(namespace, pod)
        end

        # save cmd as latest
        storage.set("exec:#{namespace}:latest:cmd", cmd)
      end

      [type, cmd]
    end

    def add_command(namespace, pod)
      type = prompt.ask('Global, namespace, pod? (g/N/p):')
      cmd = prompt.ask('Command:')

      if %w(global Global g G).include?(type)
        type = :global
        storage.set("exec:commands:global", (global_commands[:global] << cmd).uniq)
      elsif %w(pod Pod p P).include?(type)
        type = :pod
        storage.set("exec:commands:#{namespace}:#{pod_name(pod)}", (pod_commands(namespace, pod)[:pod] << cmd).uniq)
      else
        type = :namespace
        storage.set("exec:commands:#{namespace}", (namespace_commands(namespace)[:namespace] << cmd).uniq)
      end

      [type, cmd]
    end

    def run_once(namespace, pod)
      prompt.ask('Command:')
    end

    private

    def all_commands(namespace, pod, options)
      commands = [base_commands(options), global_commands, namespace_commands(namespace), pod_commands(namespace, pod)]
      commands.inject({},:update)
    end

    def base_commands(options={})
      if options[:remove]
        {base: []}
      else
        {base: ["Add command", "Run once"]}
      end
    end

    def global_commands
      {global: storage.get("exec:commands:global") || []}
    end

    def namespace_commands(namespace)
      {namespace: storage.get("exec:commands:#{namespace}") || []}
    end

    def pod_commands(namespace, pod)
      {pod: storage.get("exec:commands:#{namespace}:#{pod_name(pod)}") || []}
    end

    def pod_name(pod)
      pod.split('-')[0..-3].join('-')
    end

    def pods(namespace)
      pods_cmd = "rancher kubectl -n #{namespace} get po"
      command(printer: :null).run(pods_cmd).out.split("\n")[1..-1].map{|l| l.split(/\s+/)[0]}
    end

    def storage
      @storage ||= RanchHand::Storage.new
    end
  end
end