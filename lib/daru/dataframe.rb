module Daru
  class DataFrame

    attr_reader :vectors
    attr_reader :index
    attr_reader :name
    attr_reader :size

    # DataFrame basically consists of an Array of Vector objects.
    # These objects are indexed by row and column by vectors and index Index objects.
    def initialize source, *args
      vectors = args.shift
      index   = args.shift
      @name   = args.shift || SecureRandom.uuid

      @data = []

      if source.empty?
        @vectors = Daru::Index.new vectors
        @index   = Daru::Index.new index

        create_empty_vectors
      else
        case source
        when Array
          @vectors = Daru::Index.new (vectors + (source[0].keys - vectors)).uniq.map(&:to_sym)
          if index.nil?
            @index = Daru::Index.new source.size
          else
            @index = Daru::Index.new index
          end

          @vectors.each do |name|
            v = []

            source.each do |hsh|
              v << hsh[name]
            end

            @data << v.dv(name, @index)
          end
        when Hash
          vectors = source.keys.sort      if vectors.nil?
          index   = source.values[0].size if index.nil?

          if vectors.is_a?(Daru::Index) or index.is_a?(Daru::Index)
            @vectors = vectors
            @index   = index
          else
            @vectors = Daru::Index.new (vectors + (source.keys - vectors)).uniq.map(&:to_sym)
            @index   = Daru::Index.new index     
          end

          @vectors.each do |name|
            @data << source[name].dv(name, @index).dup
          end

          validate_labels_for source
        end
      end

      @size = @index.size

      validate
    end

    def [](*names)
      vector names
    end

    def vector *names
      unless names[1]
        @data[@vectors[names[0]]]
      end
    end

    def has_vector? name
      !!@vectors[name]
    end

    def insert_vector vector, name=nil
      
    end

    def == other
      @index == other.index and @size == other.size and 
      @vectors.each do |vector|
        self[@vectors[vector]] == other[@vectors[vector]]
      end
    end

    def method_missing(name, *args)
      if md = name.match(/(.+)\=/)
        insert_vector name[/(.+)\=/].delete("="), args[0]
      elsif self.has_vector? name
        vector name
      else
        super(name, *args)
      end
    end
   private 

    def create_empty_vectors
      @vectors.each do |name|
        @data << Daru::Vector.new(name, [], @index)
      end
    end

    def validate_labels_for source
      raise IndexError, "Expected equal number of vectors for number of Hash pairs" if 
        @vectors.size != source.size

      raise IndexError, "Expected number of indexes same as number of rows" if
        @index.size != @data[0].size
    end

    def validate
      
    end
  end
end