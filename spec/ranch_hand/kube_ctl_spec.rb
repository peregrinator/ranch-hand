RSpec.describe RanchHand::KubeCtl do
  before(:each) do
    stub_const("RanchHand::STORE_FILE", File.join('tmp/store.yml'))
    File.new(RanchHand::STORE_FILE, 'w+', 0640)
  end

  let(:kube_ctl) { RanchHand::KubeCtl.new }
  let(:k8s_pods) {
    %w(
      first-pod-1234567890-12345
      second-pod-1234567890-12345
      third-pod-1234567890-12345
    )
  }

  it "#exec calls the system command correctly" do
    allow(kube_ctl).to receive(:select_pod).and_return('first-pod-1234567890-12345')
    allow(kube_ctl).to receive(:select_command).and_return('test-command')

    expect_any_instance_of(Kernel).to receive(:system).with("rancher kubectl -n test exec -it first-pod-1234567890-12345 -- test-command")
    kube_ctl.exec('test')
  end

  it "#select_pod saves selected pod to the latest" do
    allow(kube_ctl).to receive(:pods).and_return(k8s_pods)
    allow_any_instance_of(TTY::Prompt).to receive(:enum_select).and_return(k8s_pods.first)

    kube_ctl.select_pod('test')
    expect(
      kube_ctl.send(:storage).get("exec:test:latest:pod")
    ).to eq(k8s_pods.first)
  end

  describe "#select_command" do
    it "saves the selected command to the latest" do
      allow(kube_ctl).to receive(:all_commands).and_return(['test-command'])
      allow_any_instance_of(TTY::Prompt).to receive(:enum_select).and_return('test-command')

      kube_ctl.select_command('test', 'first-pod-1234567890-12345')
      expect(
        kube_ctl.send(:storage).get("exec:test:latest:cmd")
      ).to eq('test-command')
    end

    it "calls #add_command when 'Add command' is selected" do
      allow(kube_ctl).to receive(:all_commands).and_return(['test-command'])
      allow_any_instance_of(TTY::Prompt).to receive(:enum_select).and_return('Add command')

      expect(kube_ctl).to receive(:add_command)
      kube_ctl.select_command('test', 'first-pod-1234567890-12345')
    end
  end

  describe "#add_command" do
    subject(:prompt) { TTY::TestPrompt.new }

    it "adds a global command" do
      %w(Global global g G).each do |choice|
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Global, namespace, pod? (g/N/p):').and_return(choice)
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Command:').and_return('test-command')

        kube_ctl.add_command('test', 'first-pod-1234567890-12345')
        expect(
          kube_ctl.send(:storage).get("exec:commands:global")
        ).to eq(['test-command'])
      end
    end

    it "adds a namespace command" do
      %w(Namespace namespace n N).each do |choice|
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Global, namespace, pod? (g/N/p):').and_return(choice)
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Command:').and_return('test-command')

        kube_ctl.add_command('test', 'first-pod-1234567890-12345')
        expect(
          kube_ctl.send(:storage).get("exec:commands:test")
        ).to eq(['test-command'])
      end
    end

    it "adds a pod command" do
      %w(Pod pod p P).each do |choice|
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Global, namespace, pod? (g/N/p):').and_return(choice)
        allow_any_instance_of(TTY::Prompt).to receive(:ask).with('Command:').and_return('test-command')

        kube_ctl.add_command('test', 'first-pod-1234567890-12345')
        expect(
          kube_ctl.send(:storage).get("exec:commands:test:first-pod")
        ).to eq(['test-command'])
      end
    end
  end
end