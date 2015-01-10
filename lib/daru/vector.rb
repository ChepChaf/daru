$:.unshift File.dirname(__FILE__)

require 'maths/arithmetic/vector.rb'
require 'maths/statistics/vector.rb'
require 'plotting/vector.rb'
require 'accessors/array_wrapper.rb'
require 'accessors/nmatrix_wrapper.rb'

module Daru
  class Vector
    include Enumerable
    include Daru::Maths::Arithmetic::Vector
    include Daru::Maths::Statistics::Vector
    include Daru::Plotting::Vector

    def each(&block)
      @vector.each(&block)
    end

    def map!(&block)
      @vector.map!(&block)

      self
    end

    def map(&block)
      Daru::Vector.new @vector.map(&block), name: @name, index: @index, dtype: @dtype
    end

    alias_method :recode, :map

    attr_reader :name
    attr_reader :index
    attr_reader :size
    attr_reader :dtype
    attr_reader :nm_dtype

    # Create a Vector object.
    # == Arguments
    # 
    # @param source[Array,Hash] - Supply elements in the form of an Array or a Hash. If Array, a
    #   numeric index will be created if not supplied in the options. Specifying more
    #   index elements than actual values in *source* will insert *nil* into the 
    #   surplus index elements. When a Hash is specified, the keys of the Hash are 
    #   taken as the index elements and the corresponding values as the values that
    #   populate the vector.
    # 
    # == Options
    # 
    # * +:name+  - Name of the vector
    # 
    # * +:index+ - Index of the vector
    # 
    # * +:dtype+ - The underlying data type. Can be :array or :nmatrix. Default :array.
    # 
    # * +:nm_dtype+ - For NMatrix, the data type of the numbers. See the NMatrix docs for
    #     further information on supported data type.
    # 
    # == Usage
    # 
    #   vecarr = Daru::Vector.new [1,2,3,4], index: [:a, :e, :i, :o]
    #   vechsh = Daru::Vector.new({a: 1, e: 2, i: 3, o: 4})
    def initialize source, opts={}
      index = nil
      if source.is_a?(Hash)
        index  = source.keys
        source = source.values
      else
        index  = opts[:index]
        source = source || []
      end
      name   = opts[:name]
      set_name name

      @vector = cast_vector_to(opts[:dtype], source, opts[:nm_dtype])
      @index = Daru::Index.new(index || @vector.size)
      # TODO: Will need work for NMatrix/MDArray
      if @index.size > @vector.size
        cast(dtype: :array) # NM with nils seg faults
        (@index.size - @vector.size).times { @vector << nil }
      elsif @index.size < @vector.size
        raise IndexError, "Expected index size >= vector size. Index size : #{@index.size}, vector size : #{@vector.size}"
      end

      set_size
    end

    # Get one or more elements with specified index or a range.
    # 
    # == Usage
    #   v[:one, :two] # => Daru::Vector with indexes :one and :two
    #   v[:one]       # => Single element
    #   v[:one..:three] # => Daru::Vector with indexes :one, :two and :three
    def [](index, *indexes)
      if indexes.empty?
        case index
        when Range
          range = 
          if index.first.is_a?(Numeric)
            index
          else
            first = numeric_index_for index.first
            last  = numeric_index_for index.last

            (first..last)
          end

          indexes = @index.to_a[range]
        else
          pos = numeric_index_for index
          return (pos ? @vector[pos] : nil)
        end
      else
        indexes.unshift index
      end
      Daru::Vector.new indexes.map { |index| @vector[@index[index]] },name: @name, 
        index: indexes
    end

    def []=(index, value)
      cast(dtype: :array) if value.nil?
      pos = numeric_index_for index
      @vector[pos] = value

      set_size
    end

    # Two vectors are equal if the have the exact same index values corresponding
    # with the exact same elements. Name is ignored.
    def == other
      case other
      when Daru::Vector
        @index == other.index and @size == other.size and
        @index.all? do |index|
          self[index] == other[index]
        end
      else
        # TODO: Compare against some other obj (string, number, etc.)
      end
    end

    def << element
      concat element
    end

    def push element
      concat element  
    end

    def head q=10
      self[0..q]
    end

    def tail q=10
      self[-q..-1]
    end

    # Append an element to the vector by specifying the element and index
    def concat element, index=nil
      raise IndexError, "Expected new unique index" if @index.include? index

      if index.nil? and @index.index_class == Integer
        @index = Daru::Index.new @size+1
        index  = @size
      else
        begin
          @index = Daru::Index.new(@index + index)
        rescue StandardError => e
          raise e, "Expected valid index."
        end
      end
      @vector[@index[index]] = element
      set_size
    end

    # Cast a vector to a new data type.
    # 
    # == Options
    # 
    # * +:dtype+ - :array for Ruby Array. :nmatrix for NMatrix.
    def cast opts={}
      dtype = opts[:dtype]
      raise ArgumentError, "Unsupported dtype #{opts[:dtype]}" unless 
        dtype == :array or dtype == :nmatrix

      @vector = cast_vector_to dtype
    end

    # Delete an element by value
    def delete element
      self.delete_at index_of(element)      
    end

    # Delete element by index
    def delete_at index
      idx = named_index_for index
      @vector.delete_at @index[idx]

      if @index.index_class == Integer
        @index = Daru::Index.new @size-1
      else
        @index = Daru::Index.new (@index.to_a - [idx])
      end

      set_size
    end

    # Get index of element
    def index_of element
      @index.key @vector.index(element)
    end

    # Keep only unique elements of the vector alongwith their indexes.
    def uniq
      uniq_vector = @vector.uniq
      new_index   = uniq_vector.inject([]) do |acc, element|  
        acc << index_of(element) 
        acc
      end

      Daru::Vector.new uniq_vector, name: @name, index: new_index, dtype: @dtype
    end

    # Sorts a vector according to its values. If a block is specified, the contents
    #   will be evaluated and data will be swapped whenever the block evaluates 
    #   to *true*. Defaults to ascending order sorting. Any missing values will be
    #   put at the end of the vector. Preserves indexing. Default sort algorithm is
    #   quick sort.
    # 
    # == Options
    # 
    # * +:ascending+ - if false, will sort in descending order. Defaults to true.
    # 
    # * +:type+ - Specify the sorting algorithm. Only supports quick_sort for now.
    # == Usage
    # 
    #   v = Daru::Vector.new ["My first guitar", "jazz", "guitar"]
    #   # Say you want to sort these strings by length.
    #   v.sort { |a,b| a.length < b.length }
    def sort opts={}, &block
      opts = {
        ascending: true,
        type: :quick_sort
      }.merge(opts)

      block = lambda { |a,b| a <=> b } unless block
    
      order = opts[:ascending] ? :ascending : :descending
      vector, index = send(opts[:type], @vector.to_a.dup, @index.to_a, order, &block)

      Daru::Vector.new(vector, index: index, name: @name, dtype: @dtype)
    end

    # Just sort the data and get an Array in return using Enumerable#sort. Non-destructive.
    def sorted_data &block
      @vector.to_a.sort(&block)
    end

    # Returns *true* if the value passed actually exists in the vector.
    def exists? value
      !self[index_of(value)].nil?
    end

    def n_valid
      @size
    end

    # Returns *true* if an index exists
    def has_index? index
      @index.include? index
    end

    # Convert to hash. Hash keys are indexes and values are the correspoding elements
    def to_hash
      @index.inject({}) do |hsh, index|
        hsh[index] = self[index]
        hsh
      end
    end

    # Return an array
    def to_a
      @vector.to_a
    end

    # Convert the hash from to_hash to json
    def to_json *args 
      self.to_hash.to_json
    end

    # Convert to html for iruby
    def to_html threshold=30
      name = @name || 'nil'
      html = '<table>' + '<tr><th> </th><th>' + name.to_s + '</th></tr>'
      @index.each_with_index do |index, num|
        html += '<tr><td>' + index.to_s + '</td>' + '<td>' + self[index].to_s + '</td></tr>'
    
        if num > threshold
          html += '<tr><td>...</td><td>...</td></tr>'
          break
        end
      end
      html += '</table>'

      html
    end

    def to_s
      to_html
    end

    # Over rides original inspect for pretty printing in irb
    def inspect spacing=10, threshold=15
      longest = [@name.to_s.size,
                 @index.to_a.map(&:to_s).map(&:size).max, 
                 @vector    .map(&:to_s).map(&:size).max,
                 'nil'.size].max

      content   = ""
      longest   = spacing if longest > spacing
      name      = @name || 'nil'
      formatter = "\n%#{longest}.#{longest}s %#{longest}.#{longest}s"
      content  += "\n#<" + self.class.to_s + ":" + self.object_id.to_s + " @name = " + name.to_s + " @size = " + size.to_s + " >"

      content += sprintf formatter, "", name
      @index.each_with_index do |index, num|
        content += sprintf formatter, index.to_s, (self[index] || 'nil').to_s
        if num > threshold
          content += sprintf formatter, '...', '...'
          break
        end
      end
      content += "\n"

      content
    end

    # Create a new vector with a different index.
    # 
    # @param new_index [Symbol, Array, Daru::Index] The new index. Passing *:seq*
    #   will reindex with sequential numbers from 0 to (n-1).
    def reindex new_index
      index = Daru::Index.new(new_index == :seq ? @size : new_index)

      Daru::Vector.new @vector.to_a, index: index, name: name, dtype: @dtype
    end

    # def compact!
      # TODO: Compact and also take care of indexes
      # @vector.compact!
      # set_size
    # end

    # Give the vector a new name
    # 
    # @param new_name [Symbol] The new name.
    def rename new_name
      @name = new_name.to_sym
    end

    # Duplicate elements and indexes
    def dup 
      Daru::Vector.new @vector.dup, name: @name, index: @index.dup
    end

    def daru_vector *name
      self
    end

    alias_method :dv, :daru_vector

    def method_missing(name, *args, &block)
      if name.match(/(.+)\=/)
        self[name] = args[0]
      elsif has_index?(name)
        self[name]
      else
        super(name, *args, &block)
      end
    end

   private

    def quick_sort vector, index, order, &block
      recursive_quick_sort vector, index, order, 0, @size-1, &block
      [vector, index]
    end

    def recursive_quick_sort vector, index, order, left_lower, right_upper, &block
      if left_lower < right_upper
        left_upper, right_lower = partition(vector, index, order, left_lower, right_upper, &block)
        if left_upper - left_lower < right_upper - right_lower
          recursive_quick_sort(vector, index, order, left_lower, left_upper, &block)
          recursive_quick_sort(vector, index, order, right_lower, right_upper, &block)
        else
          recursive_quick_sort(vector, index, order, right_lower, right_upper, &block)
          recursive_quick_sort(vector, index, order, left_lower, left_upper, &block)
        end
      end
    end

    def partition vector, index, order, left_lower, right_upper, &block
      mindex = (left_lower + right_upper) / 2
      mvalue = vector[mindex]
      i = left_lower
      j = right_upper
      opposite_order = order == :ascending ? :descending : :ascending

      i += 1 while(keep?(vector[i], mvalue, order, &block))
      j -= 1 while(keep?(vector[j], mvalue, opposite_order, &block))

      while i < j - 1
        vector[i], vector[j] = vector[j], vector[i]
        index[i], index[j]   = index[j], index[i]
        i += 1
        j -= 1

        i += 1 while(keep?(vector[i], mvalue, order, &block))
        j -= 1 while(keep?(vector[j], mvalue, opposite_order, &block))
      end

      if i <= j
        if i < j
          vector[i], vector[j] = vector[j], vector[i]
          index[i], index[j]   = index[j], index[i]
        end
        i += 1
        j -= 1
      end

      [j,i]
    end

    def keep? a, b, order, &block
      return false if a.nil? or b.nil?
      eval = block.call(a,b)
      if order == :ascending 
        return true  if eval == -1
        return false if eval == 1
      elsif order == :descending
        return false if eval == -1
        return true  if eval == 1
      end
      return false
    end

    # Note: To maintain sanity, this _MUST_ be the _ONLY_ place in daru where the
    #   @dtype variable is set and the underlying data type of vector changed.
    def cast_vector_to dtype, source=nil, nm_dtype=nil
      source = @vector if source.nil?
      return @vector if @dtype and @dtype == dtype

      new_vector = 
      case dtype
      when :array   then Daru::Accessors::ArrayWrapper.new(source.to_a.dup, self)
      when :nmatrix then Daru::Accessors::NMatrixWrapper.new(source.to_a.dup, 
        self, nm_dtype)
      when :mdarray then raise NotImplementedError, "MDArray not yet supported."
      else Daru::Accessors::ArrayWrapper.new(source.dup, self)
      end

      @dtype = dtype || :array
      new_vector
    end

    def named_index_for index
      if @index.include? index
        index
      elsif @index.key index
        @index.key index
      else
        raise IndexError, "Specified index #{index} does not exist."
      end
    end

    def numeric_index_for index
      if @index.include?(index) 
        @index[index]
      elsif index.is_a?(Numeric)
        index
      end
    end

    def set_size
      @size = @vector.size
    end

    def set_name name
      if name.is_a?(Numeric)
        @name = name 
      elsif name # anything but Numeric or nil
        @name = name.to_sym
      else
        @name = nil
      end
    end
  end
end