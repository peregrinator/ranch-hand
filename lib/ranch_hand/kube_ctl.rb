module RanchHand
  class KubeCtl
    include RanchHand::Commands
    
    def self.exec(namespace)
      new.exec(namespace)
    end

    def exec(namespace)
      # get_pods = Terrapin::CommandLine.new("rancher", "kubectl -n :namespace get po")
      get_pods = "rancher kubectl -n #{namespace} get po"
      pods = command(printer: :null).run(get_pods).out.split("\n")[1..-1].map{|l| l.split(/\s+/)[0]}
      
      pod = prompt.enum_select("Which pod?", pods)
      cmd = prompt.ask('What command?', default: '/bin/bash')

      system("rancher kubectl -n #{namespace} exec -it #{pod} -- #{cmd}")
    end
  end
end