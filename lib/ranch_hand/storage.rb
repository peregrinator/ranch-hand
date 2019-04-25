module RanchHand
  class Storage
    def get(key)
      store[key]
    end

    def set(key, val)
      store[key] = val
      save
    end

    private

    def store
      @store ||= YAML.load_file(RanchHand::STORE_FILE) || {}
    end

    def save
      File.open(RanchHand::STORE_FILE, 'w', 0640) do |f|
        f.write(store.to_yaml)
      end
    end
  end
end