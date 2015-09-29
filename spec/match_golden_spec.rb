require 'match_golden'

RSpec.describe 'RSpec::Matchers::Golden::match_golden' do
  include RSpec::Matchers::Golden

  context 'when comparing' do
    it 'matches relative golden file' do
      expect(1).to match_golden('gold/one.txt')
    end

    it 'matches to file with explicit path' do
      # this spec can fail if the `rspec` runs not it the project root
      expect(1).to match_golden('./spec/gold/one.txt')
    end

    it 'treats .xxx paths as relative' do
      # this spec can fail if the `rspec` runs not it the project root
      expect(1).to match_golden('.gold/one.txt')
    end

    it 'raises exception if golden file does not exist' do
      # this test will fail in recording mode.
      nofile = './spec/gold/no-file'
      # in case it was recorded:
      File.unlink(nofile) if File.file?(nofile)

      expect {
        expect(1).to match_golden(nofile)
      }.to raise_exception(ArgumentError)
    end

    it 'can compare strings as json' do
      expect('"quick brown fox"').to match_golden('gold/json_string.json')
    end

    it 'can compare hashes and arrays as json' do
      expect({fox: ['quick', 'brown'], dog: 'lazy'}).to match_golden('gold/json_structs.json')
    end

    it 'can use symbol as a formatter' do
      expect({fox: ['quick', 'brown'], dog: 'lazy'})
        .to match_golden('gold/json_structs.txt', formatter: :to_s)
    end

    def my_formatter(value)
      "custom format:\n---\n#{value.to_s}\n---"
    end

    it 'can use method as a formatter' do
      expect({fox: ['quick', 'brown'], dog: 'lazy'})
        .to match_golden('gold/json_lambda.txt', formatter: method(:my_formatter))
    end

    it 'can use lambda as a formatter' do
      expect({fox: ['quick', 'brown'], dog: 'lazy'})
        .to match_golden('gold/json_lambda.txt', formatter: lambda {|v| my_formatter(v)})
    end

    it 'can pass a block as a formatter' do
      expect({fox: ['quick', 'brown'], dog: 'lazy'})
        .to match_golden('gold/json_lambda.txt') {|v| my_formatter(v)}
    end

    it 'raises exception if both block and formatter are specified' do
      expect {
      expect({fox: ['quick', 'brown'], dog: 'lazy'})
        .to match_golden('gold/json_lambda.txt', formatter: true) {|v| my_formatter(v)}
      }.to raise_exception(ArgumentError)
    end
  end

  context 'when recording' do
    before do
      @golden = ENV[RSpec::Matchers::Golden::GOLDEN_ENV]
      ENV[RSpec::Matchers::Golden::GOLDEN_ENV] = 'record'
    end

    after do
      ENV[RSpec::Matchers::Golden::GOLDEN_ENV] = @golden
      Dir['./spec/gold/temp-*'].each {|path| File.unlink(path)}
    end

    it 'can record a file' do
      recorded_file = './spec/gold/temp-record'

      # action
      expect('foo').to match_golden(recorded_file)

      expect(File.file?(recorded_file)).to be(true)
    end

    it 'fails if file specification is broken' do
      expect {
        expect('foo').to match_golden('./spec/gold-WRONG/temp-record')
      }.to raise_exception(Errno::ENOENT)
    end
  end
end
