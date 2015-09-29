rspec-golden-matchers [![Build Status](https://travis-ci.org/seomoz/qless.svg?branch=master)](https://travis-ci.org/seomoz/qless)
===================

[RSpec 3](https://www.relishapp.com/rspec) matchers for [Golden test](http://blog.codeclimate.com/blog/2014/02/20/gold-master-testing/) regression testing (they might work for earlier versions of RSpec, and might not).

Writing good tests is hard. Luckily, no regression means that the data did not change,
and so the test can be simplified to comparing data to previous run(s).

Install
-------

Add to your Gemfile in the `:test` group:

```ruby
gem 'rspec-golden-matchers'
```

and somewhere in RSpec configuration:

```ruby
RSpec.configure do |config|
  config.include RSpecGoldenMatchers
end
```

or just in you spec(s):

```ruby
describe 'my foo spec' do
  include RSpecGoldenMatchers

  it 'foos' do
    expect(bar).to match_golden('gold/bar.json')
  end

end
```

Usage
-----

* First, we need to create gold files. To do so, we can run

```bash
mkdir spec/gold
golden=record rspec spec/foo_spec.rb
```

The `spec/gold/bar.json` is created.

* Now we can verify that there is no regression:

```bash
rspec spec/foo_spec.rb
```

API
---

API consists of single matcher:

```
match_golden(golden_filename, caller_path: ⟨…⟩, formatter: nil, &formatter_block)
```

`golden_filename` specifies location of the gold file. It can be fully specified path
(starting with either `./`, `../`, or `/`,), or path relative to the location of the
invoking spec (`caller_path`, to be precise).

`caller_path` is usually better to be left alone to its default. It is exposed primarily
to allow combining of `match_golden` into new matcher.

`formatter` and `formatter_block` - see discussion below. (Please note that `formatter`
and `formatter_block` cannot be specified simultaneously.)

To be stored and compared the actual value in the expectation needs to be converted 
to human-readable form. It is done by formatter. The formatter can be specified in several ways:

* use default formatter (`GoldenMatcher.default_formatter`, which produces json).
  ```expect(foo).to match_golden('gold/my_file.json')```

* specify `formatter` as a symbol. The symbol considered to be the object's method
  ```expect(foo).to match_golden('gold/my_file.json', formatter: :to_json)```

* specify `formatter` as a lambda/proc, or local method
  ```expect(foo).to match_golden('gold/my_file.fmt', formatter: method(:my_formatter))```

* specify as a matchers block:
  ```expect(foo).to match_golden('gold/my_file.fmt') { |actual| my_format(actual, params) }```

You can find additional examples in matcher's [spec](spec/match_golden_spec.rb).

Contribution
============

1. Fork the repository
2. Add tests for your feature
3. Write the code
4. Add documentation for your contribution
5. Send a pull request

License
=======

The software is distributed under [MIT license](LICENSE)

