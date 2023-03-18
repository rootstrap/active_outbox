module ActiveOutbox
  class Configuration
    attr_accessor :adapter

    def initialize
      @adatper = :sqlite
    end
  end
end
