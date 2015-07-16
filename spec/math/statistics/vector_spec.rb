require 'spec_helper.rb'

describe Daru::Vector do
  [:array, :gsl].each do |dtype| #nmatrix still unstable
    describe dtype do
      before do
        @dv = Daru::Vector.new [323, 11, 555, 666, 234, 21, 666, 343, 1, 2], dtype: dtype
        @dv_with_nils = Daru::Vector.new [323, 11, 555, nil, 666, 234, 21, 666, 343, nil, 1, 2]
      end

      context "#mean" do
        it "calculates mean" do
          expect(@dv.mean).to eq(282.2)
          expect(@dv_with_nils.mean).to eq(282.2)
        end
      end

      context "#sum_of_squares" do
        it "calcs sum of squares, omits nil values" do
          v = Daru::Vector.new [1,2,3,4,5,6], dtype: dtype
          expect(v.sum_of_squares).to eq(17.5)
        end
      end

      context "#standard_deviation_sample" do
        it "calcs standard deviation sample" do
          @dv_with_nils.standard_deviation_sample
        end
      end

      context "#variance_sample" do
        it "calculates sample variance" do
          expect(@dv.variance).to be_within(0.01).of(75118.84)
        end
      end

      context "#standard_deviation_population" do
        it "calculates standard deviation population" do
          @dv.standard_deviation_population
        end
      end

      context "#variance_population" do
        it "calculates population variance" do
          expect(@dv.variance_population).to be_within(0.001).of(67606.95999999999)
        end
      end

      context "#sum_of_squared_deviation" do
        it "calculates sum of squared deviation" do
          expect(@dv.sum_of_squared_deviation).to eq(676069.6)
        end
      end

      context "#skew" do
        it "calculates skewness" do
          @dv.skew
        end
      end

      context "#max" do
        it "returns the max value" do
          @dv.max
        end
      end

      context "#min" do
        it "returns the min value" do
          @dv.min
        end
      end 

      context "#sum" do
        it "returns the sum" do
          @dv.sum
        end
      end

      context "#product" do
        it "returns the product" do
          v = Daru::Vector.new [1, 2, 3, 4, 5], dtype: dtype
          expect(v.product).to eq(120)
        end
      end

      context "#median" do
        it "returns the median" do
          @dv.median
        end
      end

      context "#mode" do
        it "returns the mode" do
          @dv.mode
        end
      end

      context "#kurtosis" do
        it "calculates kurtosis" do
          @dv.kurtosis
        end
      end

      context "#count" do
        it "counts specified element" do
          @dv.count(323)
        end

        it "counts total number of elements" do
          expect(@dv.count).to eq(10)
        end
      end

      context "#coefficient_of_variation" do
        it "calculates coefficient_of_variation" do
          @dv.coefficient_of_variation
        end
      end

      context "#percentile" do
        it "calculates mid point percentile" do
          expect(@dv.percentile(50)).to eq(278.5)
        end
      end

      context "#average_deviation_population" do
        it "calculates average_deviation_population" do
          a = Daru::Vector.new([1, 2, 3, 4, 5, 6, 7, 8, 9], dtype: dtype)
          expect(a.average_deviation_population).to eq(20.quo(9).to_f)
        end
      end

      context "#proportion" do
        it "calculates proportion" do
          expect(@dv.proportion(dtype == :gsl ? 1.0 : 1)).to eq(0.1)
        end
      end

      context "#proportions" do
        it "calculates proportions" do
          @dv.proportions
        end
      end

      context "#standard_error" do
        it "calculates standard error" do
          @dv.standard_error
        end
      end

      context "#vector_standardized_compute" do
        it "calculates vector_standardized_compute" do
          @dv.vector_standardized_compute(@dv.mean, @dv.sd)
          @dv_with_nils.vector_standardized_compute(@dv.mean, @dv.sd)
        end
      end

      context "#vector_centered_compute" do
        it "calculates vector_centered_compute" do
          @dv.vector_centered_compute(@dv.mean)
          @dv_with_nils.vector_centered_compute(@dv.mean)
        end
      end
    end
  end # ALL DTYPE tests

  # Only Array tests 
  context "#percentile" do
    it "tests linear percentile strategy" do
      values = Daru::Vector.new [102, 104, 105, 107, 108, 109, 110, 112, 115, 116].shuffle
      expect(values.percentil(0, :linear)).to eq(102)
      expect(values.percentil(25, :linear)).to eq(104.75)
      expect(values.percentil(50, :linear)).to eq(108.5)
      expect(values.percentil(75, :linear)).to eq(112.75)
      expect(values.percentil(100, :linear)).to eq(116)

      values = Daru::Vector.new [102, 104, 105, 107, 108, 109, 110, 112, 115, 116, 118].shuffle
      expect(values.percentil(0, :linear)).to eq(102)
      expect(values.percentil(25, :linear)).to eq(105)
      expect(values.percentil(50, :linear)).to eq(109)
      expect(values.percentil(75, :linear)).to eq(115)
      expect(values.percentil(100, :linear)).to eq(118)
    end
  end

  context "#frequencies" do
    it "calculates frequencies" do
      vector = Daru::Vector.new([5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99])
      expect(vector.frequencies).to eq({ 
        1=>1, 2=>1, 3=>1, 4=>1, 5=>5, 
        6=>2, 7=>1, 8=>1, 9=>1,10=>1, -99=>2
      })
    end
  end

  context "#ranked" do
    it "curates by rank" do
      vector = Daru::Vector.new([nil, 0.8, 1.2, 1.2, 2.3, 18, nil])
      expect(vector.ranked).to eq(Daru::Vector.new([nil,1,2.5,2.5,4,5,nil]))

      v = Daru::Vector.new [0.8, 1.2, 1.2, 2.3, 18]
      expect(v.ranked).to eq(Daru::Vector.new [1, 2.5, 2.5, 4, 5])
    end

    it "tests paired ties" do
      a = Daru::Vector.new [0, 0, 0, 1, 1, 2, 3, 3, 4, 4, 4]
      expected = Daru::Vector.new [2, 2, 2, 4.5, 4.5, 6, 7.5, 7.5, 10, 10, 10]
      expect(a.ranked).to eq(expected)
    end
  end

  context "#dichotomize" do
    it "dichotomizes" do
      a = Daru::Vector.new [0, 0, 0, 1, 2, 3, nil]
      exp = Daru::Vector.new [0, 0, 0, 1, 1, 1, nil]
      expect(a.dichotomize).to eq(exp)

      a = Daru::Vector.new [1, 1, 1, 2, 2, 2, 3]
      exp = Daru::Vector.new [0, 0, 0, 1, 1, 1, 1]
      expect(a.dichotomize).to eq(exp)

      a = Daru::Vector.new [0, 0, 0, 1, 2, 3, nil]
      exp = Daru::Vector.new [0, 0, 0, 0, 1, 1, nil]
      expect(a.dichotomize(1)).to eq(exp)

      a = Daru::Vector.new %w(a a a b c d)
      exp = Daru::Vector.new [0, 0, 0, 1, 1, 1]
      expect(a.dichotomize).to eq(exp)
    end
  end

  context "#median_absolute_deviation" do
    it "calculates median_absolute_deviation" do
      a = Daru::Vector.new [1, 1, 2, 2, 4, 6, 9]
      expect(a.median_absolute_deviation).to eq(1)
    end
  end

  context "#round" do
    it "rounds non-nil values" do
      vector = Daru::Vector.new([1.44,55.32,nil,4])
      expect(vector.round(1)).to eq(Daru::Vector.new([1.4,55.3,nil,4]))
    end
  end

  context "#center" do
    it "centers" do
      mean = rand
      samples = 11
      centered = Daru::Vector.new(samples.times.map { |i| i - ((samples / 2).floor).to_i })
      not_centered = centered.recode { |v| v + mean }
      obs = not_centered.center
      centered.each_with_index do |v, i|
        expect(v).to be_within(0.0001).of(obs[i])
      end
    end
  end

  context "#standardize" do
    it "returns a standardized vector" do
      vector = Daru::Vector.new([11,55,33,25,nil,22])
      expect(vector.standardize.round(2)).to eq(
        Daru::Vector.new([-1.11, 1.57, 0.23, -0.26,nil, -0.44])
        )
    end

    it "tests for vector standardized with zero variance" do
      v1 = Daru::Vector.new 100.times.map { |_i| 1 }
      exp = Daru::Vector.new 100.times.map { nil }
      expect(v1.standardize).to eq(exp)
    end
  end

  context "#vector_percentile" do
    it "replaces each non-nil value with its percentile value" do
      vector = Daru::Vector.new([1,nil,nil,2,2,3,4,nil,nil,5,5,5,6,10])
      expect(vector.vector_percentile).to eq(Daru::Vector.new(
        [10,nil,nil,25,25,40,50,nil,nil,70,70,70,90,100])
      )
    end
  end
  
  context "#sample_with_replacement" do
    it "calculates sample_with_replacement" do
      vec =  Daru::Vector.new(
        [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, nil, -99, -99], 
        name: :common_all_dtypes)
      srand(1)
      expect(vec.sample_with_replacement(100).size).to eq(100)

      srand(1)
      expect(vec.sample_with_replacement(100).size).to eq(100)
    end
  end

  context "#sample_without_replacement" do
    it "calculates sample_without_replacement" do
      vec =  Daru::Vector.new(
        [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, nil, -99, -99], 
        name: :common_all_dtypes)

      srand(1)
      expect(vec.sample_without_replacement(17).sort).to eq(
        vec.only_valid.to_a.sort)
      expect {
        vec.sample_without_replacement(20)
      }.to raise_error(ArgumentError)

      srand(1)
      expect(vec.sample_without_replacement(17).sort).to eq(
        vec.only_valid.to_a.sort)
    end
  end

  context "#jackknife" do
    it "jack knife correctly with named method" do
      a = Daru::Vector.new [1, 2, 3, 4]
      df = a.jackknife(:mean)
      expect(df[:mean].mean).to eq (a.mean)

      df = a.jackknife([:mean, :sd])
      expect(df[:mean].mean).to eq(a.mean)
      expect(df[:mean].sd).to eq(a.sd)
    end

    it "jack knife correctly with custom method" do
      a   = Daru::Vector.new [17.23, 18.71, 13.93, 18.81, 15.78, 11.29, 14.91, 13.39, 18.21, 11.57, 14.28, 10.94, 18.83, 15.52, 13.45, 15.25]
      ds  = a.jackknife(log_s2: ->(v) {  Math.log(v.variance) })
      exp = Daru::Vector.new [1.605, 2.972, 1.151, 3.097, 0.998, 3.308, 0.942, 1.393, 2.416, 2.951, 1.043, 3.806, 3.122, 0.958, 1.362, 0.937]

      expect_correct_vector_in_delta ds[:log_s2], exp, 0.001
      # expect(ds[:log_s2]).to be_within(0.001).of(exp)
      expect(ds[:log_s2].mean).to be_within(0.00001).of(2.00389)
      expect(ds[:log_s2].variance).to be_within(0.001).of(1.091)
    end

    it "jack knife correctly with k > 1" do
      rng = Distribution::Normal.rng(0,1)
      a   = Daru::Vector.new_with_size(6) { rng.call}
      
      ds = a.jackknife(:mean, 2)
      mean = a.mean
      exp = Daru::Vector.new [3 * mean - 2 * (a[2] + a[3] + a[4] + a[5]) / 4, 3 * mean - 2 * (a[0] + a[1] + a[4] + a[5]) / 4, 3 * mean - 2 * (a[0] + a[1] + a[2] + a[3]) / 4]
      expect_correct_vector_in_delta(exp, ds[:mean], 1e-13)
    end
  end

  before do
    # daily closes of iShares XIU on the TSX
    @shares = Daru::Vector.new([17.28, 17.45, 17.84, 17.74, 17.82, 17.85, 17.36, 17.3, 17.56, 17.49, 17.46, 17.4, 17.03, 17.01,
      16.86, 16.86, 16.56, 16.36, 16.66, 16.77])
  end

  context "#acf" do
    it "calculates autocorrelation co-efficients" do
      acf = @shares.acf

      expect(acf.length).to eq(14)

      # test the first few autocorrelations
      expect(acf[0]).to be_within(0.0001).of(1.0)
      expect(acf[1]).to be_within(0.001) .of(0.852)
      expect(acf[2]).to be_within(0.001) .of(0.669)
      expect(acf[3]).to be_within(0.001) .of(0.486)
    end
  end

  context "#diff" do
    it "performs the difference of the series" do
      diff = @shares.diff

      expect(diff[@shares.size - 1]).to be_within(0.001).of( 0.11)
      expect(diff[@shares.size - 2]).to be_within(0.001).of( 0.30)
      expect(diff[@shares.size - 3]).to be_within(0.001).of(-0.20)
    end
  end

  context "#ma" do
    it "calculates moving average" do
      # test default
      ma10 = @shares.ma

      expect(ma10[-1]) .to be_within(0.001).of(16.897)
      expect(ma10[-5]) .to be_within(0.001).of(17.233)
      expect(ma10[-10]).to be_within(0.001).of(17.587)

      # test with a different lookback period
      ma5 = @shares.ma 5

      expect(ma5[-1]).to be_within(0.001).of(16.642)
      expect(ma5[-10]).to be_within(0.001).of(17.434)
      expect(ma5[-15]).to be_within(0.001).of(17.74)
    end
  end

  context "#ema" do
    it "calculates exponential moving average" do
      # test default
      ema10 = @shares.ema

      expect(ema10[-1]) .to be_within(0.00001).of( 16.87187)
      expect(ema10[-5]) .to be_within(0.00001).of( 17.19187)
      expect(ema10[-10]).to be_within(0.00001).of( 17.54918)

      # test with a different lookback period
      ema5 = @shares.ema 5

      expect(ema5[-1]) .to be_within( 0.0001).of(16.71299)
      expect(ema5[-10]).to be_within( 0.0001).of(17.49079)
      expect(ema5[-15]).to be_within( 0.0001).of(17.70067)

      # test with a different smoother
      ema_w = @shares.ema 10, true

      expect(ema_w[-1]) .to be_within(0.00001).of(17.08044)
      expect(ema_w[-5]) .to be_within(0.00001).of(17.33219)
      expect(ema_w[-10]).to be_within(0.00001).of(17.55810)
    end
  end

  context "#macd" do
    it "calculates moving average convergence divergence" do
      # MACD uses a lot more data than the other ones, so we need a bigger vector
      data = Daru::Vector.new(
        File.readlines("spec/fixtures/stock_data.csv").map(&:to_f))

      macd, signal = data.macd

      # check the MACD
      expect(macd[-1]).to be_within(1e-6).of(3.12e-4)
      expect(macd[-10]).to be_within(1e-4).of(-1.07e-2)
      expect(macd[-20]).to be_within(1e-5).of(-5.65e-3)

      # check the signal
      expect(signal[-1]).to be_within(1e-5).of(-0.00628)
      expect(signal[-10]).to be_within(1e-5).of(-0.00971)
      expect(signal[-20]).to be_within(1e-5).of(-0.00338)
    end
  end
end