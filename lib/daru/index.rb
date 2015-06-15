module Daru
  class Index
    include Enumerable

    def each(&block)
      @relation_hash.each_key(&block)
      self
    end

    def map(&block)
      to_a.map(&block)
    end

    attr_reader :relation_hash

    attr_reader :size

    attr_reader :index_class

    def initialize index, values=nil
      @relation_hash = {}

      index = 0                         if index.nil?
      index = Array.new(index) { |i| i} if index.is_a? Integer
      index = index.to_a                if index.is_a? Daru::Index

      if values.nil?
        index.each_with_index do |n, idx|
          @relation_hash[n] = idx 
        end
      else
        raise IndexError, "Size of values : #{values.size} and index : #{index.size} do not match" if
          index.size != values.size

        values.each_with_index do |value,i|
          @relation_hash[index[i]] = value
        end
      end

      @relation_hash.freeze
      @size = @relation_hash.size

      if index[0].is_a?(Integer)
        @index_class = Integer
      else
        @index_class = Symbol
      end
    end

    def ==(other)
      return false if other.size != @size

      @relation_hash.keys == other.to_a and @relation_hash.values == other.relation_hash.values
    end

    def [](*key)
      loc = key[0]

      case 
      when loc.is_a?(Range)
        first = loc.first
        last = loc.last

        slice first, last
      when key.size > 1
        Daru::Index.new key.map { |k| self[k] }, key
      else
        v = @relation_hash[loc]
        return loc if v.nil?
        v
      end
    end

    def slice *args
      start   = args[0]
      en      = args[1]
      indexes = []

      if start.is_a?(Integer) and en.is_a?(Integer)
        (start..en).each do |idx|
          indexes << @relation_hash.key(idx)
        end

        Index.new indexes, (start..en).to_a
      else
        keys      = @relation_hash.keys
        start_idx = keys.index(start)
        en_idx    = keys.index(en)

        for i in start_idx..en_idx
          indexes << keys[i]
        end

        Index.new indexes, (start_idx..en_idx).to_a
      end
    end

    def +(other)
      if other.respond_to? :relation_hash #another index object
        (@relation_hash.keys + other.relation_hash.keys).uniq.to_index
      elsif other.is_a?(Symbol) or other.is_a?(Integer)
        (@relation_hash.keys << other).uniq.to_index
      else
        (@relation_hash.keys + other).uniq.to_index
      end
    end

    def to_a
      @relation_hash.keys
    end

    def key(value)
      @relation_hash.keys[value]
    end

    def include? index
      @relation_hash.has_key? index
    end

    def empty?
      @relation_hash.empty?
    end

    def dup
      Daru::Index.new @relation_hash.keys
    end

    def _dump depth
      Marshal.dump({relation_hash: @relation_hash})
    end

    def self._load data
      h = Marshal.load data

      Daru::Index.new(h[:relation_hash].keys, h[:relation_hash].values)
    end
  end
end