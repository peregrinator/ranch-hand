module RanchHand
  module Commands
    private

    def command(opts={})
      TTY::Command.new(**opts)
    end

    def prompt
      TTY::Prompt.new
    end
  end
end