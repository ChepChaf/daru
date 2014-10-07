daru
====

Data Analysis in RUby

## Introduction

daru (Data Analysis in RUby) is a library for storage, analysis and manipulation of data. It aims to be the preferred data analysis library for Ruby. 

Development of daru was started to address the fragmentation of Dataframe-like classes which were created in many ruby gems as per their own needs. 

This creates a hurdle in using these gems together to solve a problem. For example, calculating something in [statsample](https://github.com/clbustos/statsample) and plotting the results in [Nyaplot](https://github.com/domitry/nyaplot).

daru is heavily inspired by `Statsample::Dataset`, `Nyaplot::DataFrame` and the super-awesome pandas, a very mature solution in Python.

## Data Structures

daru employs several data structures for storing and manipulating data:
* Vector - A basic 1-D vector.
* DataFrame - A 2-D matrix-like structure which is internally composed of named `Vector` classes.

daru data structures can be constructed by using several Ruby classes. These include `Array`, `Hash`, `Matrix`, [NMatrix](https://github.com/SciRuby/nmatrix) and [MDArray](https://github.com/rbotafogo/mdarray). daru brings a uniform API for handling and manipulating data represented in any of the above Ruby classes.

## Testing

Install jruby using `rvm install jruby`, then run `jruby -S gem install mdarray`, followed by `bundle install`. You will need to install `mdarray` manually because of strange gemspec file behaviour. If anyone can automate this then I'd greatly appreciate it! Then run `rspec` in JRuby to test for MDArray functionality.

Then switch to MRI, do a normal `bundle install` followed by `rspec` for testing everything else with NMatrix functionality.

## Roadmap

* Automate testing for both MRI and JRuby.
* Enable creation of DataFrame by only specifying an NMatrix/MDArray in initialize. Vector naming happens automatically (alphabetic) or is specified in an Array.
* Add support for missing values in vectors.