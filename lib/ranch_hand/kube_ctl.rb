module RanchHand
  class KubeCtl
    include RanchHand::Commands
    
    def self.exec(namespace)
      new.exec(namespace)
    end

    def exec(namespace)
      pod = select_pod(namespace)
      cmd = select_command(namespace, pod)
      
      # run cmd
      system("rancher kubectl -n #{namespace} exec -it #{pod} -- #{cmd}")
    end

    def select_pod(namespace)
      pods = pods(namespace)
      pod = prompt.enum_select("Which pod?", pods, per_page: 10,
        default: pods.index(
          storage.get("exec:#{namespace}:latest:pod")
        ).to_i + 1
      )
      storage.set("exec:#{namespace}:latest:pod", pod)
      pod
    end

    def select_command(namespace, pod)
      commands =  ["Add command"] + all_commands(namespace, pod)
      cmd = prompt.enum_select('What command?', commands, per_page: 10,
        default: commands.index(
          storage.get("exec:#{namespace}:latest:cmd")
        ).to_i + 1
      )

      if cmd == "Add command"
        cmd = add_command(namespace, pod)
      end

      # save cmd as latest
      storage.set("exec:#{namespace}:latest:cmd", cmd)

      cmd
    end

    def add_command(namespace, pod)
      type = prompt.ask('Global, namespace, pod? (g/N/p):')
      cmd = prompt.ask('Command:')

      if %w(global Global g G).include?(type)
        storage.set("exec:commands:global", (global_commands << cmd).uniq)
      elsif %w(pod Pod p P).include?(type)
        storage.set("exec:commands:#{namespace}:#{pod_name(pod)}", (pod_commands(namespace, pod) << cmd).uniq)
      else
        storage.set("exec:commands:#{namespace}", (namespace_commands(namespace) << cmd).uniq)
      end

      cmd
    end

    private

    def all_commands(namespace, pod)
      global_commands | namespace_commands(namespace) | pod_commands(namespace, pod)
    end

    def global_commands
      storage.get("exec:commands:global") || []
    end

    def namespace_commands(namespace)
      storage.get("exec:commands:#{namespace}") || []
    end

    def pod_commands(namespace, pod)
      storage.get("exec:commands:#{namespace}:#{pod_name(pod)}") || []
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