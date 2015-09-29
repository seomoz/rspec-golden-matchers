require 'rake'

trap 'USR1' do
  threads = Thread.list

  puts
  puts "=" * 80
  puts "Received USR1 signal; printing all #{threads.count} thread backtraces."

  threads.each do |thr|
    description = if thr == Thread.main
                    "Main thread"
                  else
                    thr.inspect
                  end
    puts
    puts "#{description} backtrace: "
    puts thr.backtrace.join("\n")
  end

  puts "=" * 80
end

desc "run tests"
task :test do
  sh "bundle exec rspec spec"
end
