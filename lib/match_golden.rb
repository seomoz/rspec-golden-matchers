require 'json'
require 'pathname'
require 'tempfile'

# Golden test helper: test value against saved in the file. If the saved value
# (_golden master_) does not match the actual value, the `diff` is
# printed, and the test fails.
#
# The typical use:
# ```
#   expect(2 + 2).to match_golden("gold/four.txt")
# ```
# To record golden master, run
# `> golden=record rspec spec/myspec.rb`
#
# To verify it is matching,
# `> golden=record rspec spec/myspec.rb`
#
# By convention, names that start with `/` or `.` are considered fully
# specified. The rest of names is considered to be relative path from the
# directory where the test file located. It would be nice to place all
# masters in `gold/` for consistency.
#
# There are several consideration in choice of formatter:
# * It needs to preserve all relevant information (there is no value in the spec otherwise, is it?)
# * It should be able to handle gracefully all expected inputs.
# * It needs to produce sufficiently sparce output so `diff` is easy to read.
module RSpec::Matchers::Golden

  GOLDEN_ENV = 'golden'

  class GoldenMatcher
    def initialize(golden_filename, caller_path, formatter)
      @filename = expanded_filename(golden_filename, caller_path)
      @formatter = formatter
    end

    def matches?(value)
      @value = value
      if compare?
        compare_to_golden
      else
        record_golden
        return true
      end
    end

    def failure_message
      "expected #{@value.inspect} does not match golden file '#{@filename}'"
    end

    def failure_message_when_negated
      "expected #{@value.inspect} matches golden file '#{@filename}'"
    end

    def self.default_formatter(value)
      ::JSON.pretty_generate(value)
    rescue JSON::GeneratorError
      value.to_json
    end

  private
    def compare?
      ENV[GOLDEN_ENV] != 'record'
    end

    def expanded_filename(golden_filename, caller_path)
      if golden_filename =~ %r[^\.{,2}/]
        golden_filename
      else
        Pathname.new(caller_path).dirname.join(golden_filename).to_s
      end
    end

    def formatted_value
      case @formatter
      when Symbol
        @value.public_send(@formatter)
      else
        @formatter.call(@value)
      end
    end

    def check_golden_exists
      raise ArgumentError.new("golden file '#{@filename}' not found") unless File.exist?(@filename)
    end

    def build_temp_file
      Tempfile.new('actual').tap do |tempfile|
        tempfile.write(formatted_value)
        tempfile.close(false)
      end
    end

    def diff_files(tempfile_name)
      system "diff '#{tempfile_name}' '#{@filename}'"
      $?.to_i == 0
    end

    def compare_to_golden
      check_golden_exists
      tempfile = build_temp_file
      ok = diff_files(tempfile.path)
      tempfile.delete
      return ok
    end

    def record_golden
      File.write(@filename, formatted_value)
    end
  end

  class JsonFormatter

    def initialize(args={})
      @excluded = (ex = args[:excluded]) && ex.map { |k| k.to_sym }
    end

    def deep_exclude(element)
      return element unless @excluded && @excluded.size > 0
      case element
        when Hash
          element.inject({}) do |hash, (key, value)|
            unless @excluded.include? key.to_sym
              hash[key] = deep_type?(value) ? deep_exclude(value) : value
            end
            hash
          end
        when Array
          element.inject([]) do |array, value|
            array.push(deep_type?(value) ? deep_exclude(value) : value)
          end
        else
          element
      end
    end

    def deep_type?(element)
      element != nil && (element.kind_of?(Hash) || element.kind_of?(Array))
    end

    def call(value)
      raise ArgumentError.new('The input must be a hash') unless value.kind_of? Hash
      excluded_value = deep_exclude(value)
      begin
        ::JSON.pretty_generate(excluded_value)
      rescue JSON::GeneratorError
        excluded_value.to_json
      end
    end
  end


  # A matcher for the file.
  #
  # `golden_filename` specifies stored location of the data. If the filename starts with `./`,
  # `../`, or `/`, it is considered fully specified, and used as-is. Otherwise it is treated as
  # location relative to location of the invoking spec (or, more precisely, to `caller_path`).
  #
  # There is four ways to specify formatter:
  # (1) omit it -- use default formatter (`GoldenMatcher.default_formatter`, which produces json).
  #     ```expect(foo).to match_golden('gold/my_file.json')```
  # (2) specify formatter as a symbol. The symbol considered to be the object's method
  #     ```expect(foo).to match_golden('gold/my_file.json', formatter: :to_json)```
  # (3) specify formatter as a lambda/proc, or local method
  #     ```expect(foo).to match_golden('gold/my_file.fmt', formatter: method(:my_formatter))```
  # (4) specify formatter as matchers block:
  #     ```expect(foo).to match_golden('gold/my_file.fmt') { |actual| my_format(actual, params) }```
  #
  # `caller_path` is not expected to be used in specs. It however can become handy when new matchers
  # are constructed from `match_golden`
  def match_golden(golden_filename,
                   caller_path: caller_locations(1..1).first.path,
                   formatter: nil,
                   &formatter_block)
    if !formatter.nil? and !formatter_block.nil?
      raise ArgumentError.new('formatter and block cannot be specified simultaneously')
    end
    GoldenMatcher.new(golden_filename, caller_path,
                      formatter || formatter_block || GoldenMatcher.method(:default_formatter))
  end


  # A matcher for the file using the json formatter, enabled to exclude keys from the comparison
  #
  # `golden_filename` specifies stored location of the data. If the filename starts with `./`,
  # `../`, or `/`, it is considered fully specified, and used as-is. Otherwise it is treated as
  # location relative to location of the invoking spec (or, more precisely, to `caller_path`).
  #
  # `caller_path` is not expected to be used in specs. It however can become handy when new matchers
  # are constructed from `match_golden`
  #
  # `excluded` is a list with the name of the keys to be excluded from the comparison. For example:
  # [:id, :created_at, :updated_at] if you are working with active record
  def match_golden_json(golden_filename,
                        caller_path: caller_locations(1..1).first.path,
                        excluded: nil)
    match_golden(golden_filename, caller_path: caller_path, formatter: JsonFormatter.new(excluded: excluded))
  end
end
