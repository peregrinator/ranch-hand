require 'spec_helper'

RSpec.describe RanchHand::KubeCtl do
  before(:each) do
    stub_const("RanchHand::STORE_FILE", File.join('tmp/store.yml'))
    File.new(RanchHand::STORE_FILE, 'w+', 0640)
  end

  let(:kube_ctl) { RanchHand::KubeCtl.new }
  let(:k8s_pods) {
    %w(
      apache-1234567890-12345
      haproxy-1234567890-12345
      nginx-1234567890-12345
      nginx-1234567890-67890
      nginx-1234567890-54321
    )
  }

  describe "#exec" do
    it "calls #choose_command by default" do
      expect(kube_ctl).to receive(:choose_command)
      kube_ctl.exec(cmd_options: {namespace: 'test'})
    end

    it "calls #remove_command if passed :remove switch" do
      expect(kube_ctl).to receive(:remove_command)
      kube_ctl.exec(cmd_options: {namespace: 'test', remove: true})
    end

    it "calls #repeat_command if passed :repeat switch" do
      expect(kube_ctl).to receive(:repeat_command)
      kube_ctl.exec(cmd_options: {namespace: 'test', repeat: true})
    end

    describe "with command passed via :command flag" do
      it "requests pod and runs command passed via :command flag" do
        namespace, pod, cmd, args = 'test', 'first-pod-1234567890-12345', 'test-command', ['a', 'b']
        expect(kube_ctl).to receive(:select_pod).and_return(pod)
        expect(kube_ctl).to receive(:run_command).with(namespace, pod, cmd, args)

        kube_ctl.exec(args: args, cmd_options: {namespace: namespace, command: cmd})
      end

      it "adds the configured :command_prefix when present" do
        namespace, pod, cmd_prefix, cmd, args = 'test', 'first-pod-1234567890-12345', 'su - app', 'test-command', ['a', 'b']
        expect(kube_ctl).to receive(:select_pod).and_return(pod)
        expect(kube_ctl).to receive(:run_command).with(namespace, pod, "#{cmd_prefix} #{cmd}", args)

        kube_ctl.exec(args: args, cmd_options: {namespace: namespace, command: cmd, command_prefix: cmd_prefix})
      end

      it "does not add the configured :command_prefix when :skip_prefix is set to true" do
        namespace, pod, cmd_prefix, cmd, args = 'test', 'first-pod-1234567890-12345', 'su - app', 'test-command', ['a', 'b']
        expect(kube_ctl).to receive(:select_pod).and_return(pod)
        expect(kube_ctl).to receive(:run_command).with(namespace, pod, cmd, args)

        kube_ctl.exec(args: args, cmd_options: {namespace: namespace, command: cmd, command_prefix: cmd_prefix, skip_prefix: true})
      end
    end
  end

  it "#choose_command calls the system command correctly" do
    allow(kube_ctl).to receive(:select_pod).and_return('first-pod-1234567890-12345')
    allow(kube_ctl).to receive(:select_command).and_return([:global, 'test-command arg1'])

    expect_any_instance_of(Kernel).to receive(:system).with("rancher kubectl -n test exec -it first-pod-1234567890-12345 -- test-command arg1")
    kube_ctl.choose_command('test')
  end

  describe "#remove_command" do
    before(:each) do
      allow(kube_ctl).to receive(:select_pod).and_return('first-pod-1234567890-12345')
    end

    it "removes the selected :global command" do
      kube_ctl.send(:storage).set("exec:commands:global", ['test-command-A arg1', 'test-command-B'])
      allow(kube_ctl).to receive(:select_command).and_return([:global, 'test-command-A arg1'])

      kube_ctl.remove_command('test')
      expect(
        kube_ctl.send(:storage).get("exec:commands:global")
      ).to eq(['test-command-B'])
    end

    it "removes the selected :namespace command" do
      kube_ctl.send(:storage).set("exec:commands:test", ['test-command-A arg1', 'test-command-B'])
      allow(kube_ctl).to receive(:select_command).and_return([:namespace, 'test-command-A arg1'])

      kube_ctl.remove_command('test')
      expect(
        kube_ctl.send(:storage).get("exec:commands:test")
      ).to eq(['test-command-B'])
    end

    it "removes the selected :pod command" do
      kube_ctl.send(:storage).set("exec:commands:test:first-pod", ['test-command-A arg1', 'test-command-B'])
      allow(kube_ctl).to receive(:select_command).and_return([:pod, 'test-command-A arg1'])

      kube_ctl.remove_command('test')
      expect(
        kube_ctl.send(:storage).get("exec:commands:test:first-pod")
      ).to eq(['test-command-B'])
    end
  end

  it "#repeat_command runs previously used command" do
    namespace, pod, cmd = ['test', 'first-pod-1234567890-12345', 'test-command arg1']
    kube_ctl.send(:storage).set("exec:#{namespace}:latest:pod", pod)
    kube_ctl.send(:storage).set("exec:#{namespace}:latest:cmd", cmd)

    expect_any_instance_of(Kernel).to receive(:system).with("rancher kubectl -n test exec -it first-pod-1234567890-12345 -- test-command arg1")
    kube_ctl.repeat_command(namespace)
  end

  describe "#select_pod" do
    let(:prompt) { TTY::Prompt::Test.new }
    before(:each) do
      allow(kube_ctl).to receive(:prompt).and_return(prompt)
      allow(kube_ctl).to receive(:pods).and_return(k8s_pods)
    end

    it "saves selected pod to the latest" do
      # make a selection
      prompt.input << "1\n"
      prompt.input.rewind

      kube_ctl.select_pod('test')

      expect(
        kube_ctl.send(:storage).get("exec:test:latest:pod")
      ).to eq(k8s_pods.first)
    end

    context "filter flag (-f/--filter)" do
      it "limits pods returned to those matching the filter" do
        # make a selection
        prompt.input << "1\n"
        prompt.input.rewind

        kube_ctl.select_pod('test', {filter: "nginx"})

        expect(
          prompt.output.string.split("Choose 1-").first.scan(/nginx/).size
        ).to eq(3)
        expect(
          prompt.output.string.include?('apache')
        ).to be(false)
      end

      it "limits pods returned to those not matching the filter when passed a negative filter string" do
        # make a selection
        prompt.input << "1\n"
        prompt.input.rewind

        kube_ctl.select_pod('test', {filter: "-nginx"})

        expect(
          prompt.output.string.include?('nginx')
        ).to be(false)
        expect(
          prompt.output.string.include?('apache')
        ).to be(true)
      end
    end

    context "group switch (-g/--group)" do
      it "groups pods such that there is only one occurance of each" do
        # make a selection
        prompt.input << "1\n"
        prompt.input.rewind

        kube_ctl.select_pod('test', {group: true})

        expect(
          prompt.output.string.split("Choose 1-").first.scan(/nginx/).size
        ).to eq(1)
      end
    end

    context "pod flag (-p/--pod)" do
      context "without group switch" do
        it "returns the matching pod when there is a full pod identifier provided" do
          namespace, pod = 'test', 'nginx-1234567890-67890'

          expect(
            kube_ctl.select_pod(namespace, {pod: pod})
          ).to eq(pod)
        end

        it "does not return the matching pod when there is a full pod identifier provided" do
          namespace, pod = 'test', 'nginx'

          expect(prompt).to receive(:error).with("No pods match: '#{pod}'. Did you mean to use the group (-g) switch?")
          expect(
            kube_ctl.select_pod(namespace, {pod: pod})
          ).to eq(nil)
        end
      end

      context "with group switch" do
        it "returns the first matching pod when only a partial pod identifier is provided" do
          namespace, pod = 'test', 'nginx'

          expect(
            kube_ctl.select_pod(namespace, {pod: pod, group: true})
          ).to eq('nginx-1234567890-12345')
        end
      end
    end
  end

  describe "#select_command" do
    it "saves the selected command to the latest" do
      allow(kube_ctl).to receive(:all_commands).and_return({global: ['test-command arg1']})
      allow_any_instance_of(TTY::Prompt).to receive(:enum_select).and_return([:global, 'test-command arg1'])

      kube_ctl.select_command('test', 'first-pod-1234567890-12345')
      expect(
        kube_ctl.send(:storage).get("exec:test:latest:cmd")
      ).to eq('test-command arg1')
    end

    it "calls #add_command when 'Add command' is selected" do
      allow(kube_ctl).to receive(:all_commands).and_return({global: ['test-command arg1']})
      allow_any_instance_of(TTY::Prompt).to receive(:enum_select).and_return([:base, 'Add command'])

      expect(kube_ctl).to receive(:add_command)
      kube_ctl.select_command('test', 'first-pod-1234567890-12345')
    end

    it "calls #run_once when 'Run once' is selected" do
      allow(kube_ctl).to receive(:all_commands).and_return({global: ['test-command arg1']})
      allow_any_instance_of(TTY::Prompt).to receive(:enum_select).and_return([:base, 'Run once'])

      expect(kube_ctl).to receive(:run_once)
      kube_ctl.select_command('test', 'first-pod-1234567890-12345')
    end
  end

  describe "#add_command" do
    subject(:prompt) {TTY::Prompt::Test.new }

    it "adds a global command" do
      %w(Global global g G).each do |choice|
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Global, namespace, pod? (g/N/p):').and_return(choice)
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Command:').and_return('test-command arg1')

        kube_ctl.add_command('test', 'first-pod-1234567890-12345')
        expect(
          kube_ctl.send(:storage).get("exec:commands:global")
        ).to eq(['test-command arg1'])
      end
    end

    it "adds a namespace command" do
      %w(Namespace namespace n N).each do |choice|
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Global, namespace, pod? (g/N/p):').and_return(choice)
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Command:').and_return('test-command arg1')

        kube_ctl.add_command('test', 'first-pod-1234567890-12345')
        expect(
          kube_ctl.send(:storage).get("exec:commands:test")
        ).to eq(['test-command arg1'])
      end
    end

    it "adds a pod command" do
      %w(Pod pod p P).each do |choice|
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Global, namespace, pod? (g/N/p):').and_return(choice)
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Command:').and_return('test-command arg1')

        kube_ctl.add_command('test', 'first-pod-1234567890-12345')
        expect(
          kube_ctl.send(:storage).get("exec:commands:test:first-pod")
        ).to eq(['test-command arg1'])
      end
    end
  end

  it "#run_once returns the provided command" do
    expect_any_instance_of(TTY::Prompt).to receive(:ask).with('Command:').and_return('test-command arg1')

    expect(
      kube_ctl.run_once('test', 'first-pod-1234567890-12345')
    ).to eq('test-command arg1')
  end
end
