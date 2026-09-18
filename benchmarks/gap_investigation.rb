# frozen_string_literal: true

# Investigates why strip_types is 1.21x slower than plain Ruby.
# Tests four hypotheses:
#   1. Object allocation (new instance per call)
#   2. TracePoint still active during calls
#   3. class_eval overhead persisting at runtime
#   4. Method lookup after prepend chain

require 'benchmark/ips'
require_relative '../lib/lowtype'

LowType.configure { |c| c.type_checking = false }

# Plain Ruby -- absolute baseline, no LowType at all
class PlainBaseline
  def greet(name: 'World')
    "Hello, #{name}!"
  end
end

# Rewritten via LowType strip_types
class RewrittenMethod
  include LowType

  def greet(name: String | value('World'))
    "Hello, #{name}!"
  end
end

# Plain Ruby with same default value as rewritten version
class PlainWithDefault
  def greet(name: 'World')
    "Hello, #{name}!"
  end
end

# Check if TracePoint is still active after class load
tp_count = 0
TracePoint.trace(:call) { |tp| tp_count += 1 if tp.method_id == :greet }

plain = PlainBaseline.new
rewritten = RewrittenMethod.new

puts "\n== Hypothesis 1: Is TracePoint still firing during method calls? =="
tp_count = 0
10.times { rewritten.greet(name: 'test') }
puts "TracePoint :call events for rewritten#greet after 10 calls: #{tp_count}"
tp_count = 0
10.times { plain.greet(name: 'test') }
puts "TracePoint :call events for plain#greet after 10 calls: #{tp_count}"
TracePoint.trace(:call).disable rescue nil

puts "\n== Hypothesis 2: Prepend chain depth =="
puts "RewrittenMethod ancestors: #{RewrittenMethod.ancestors.first(5).inspect}"
puts "PlainBaseline ancestors:   #{PlainBaseline.ancestors.first(5).inspect}"

puts "\n== Hypothesis 3: Method defined where? =="
puts "RewrittenMethod#greet defined in: #{RewrittenMethod.instance_method(:greet).owner}"
puts "PlainBaseline#greet defined in:   #{PlainBaseline.instance_method(:greet).owner}"

puts "\n== Benchmark: Plain vs Rewritten (no object allocation) =="
Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('plain baseline')   { plain.greet(name: 'World') }
  x.report('rewritten')        { rewritten.greet(name: 'World') }

  x.compare!
end

puts "\n== Benchmark: With object allocation (new each time) =="
Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('plain baseline')   { PlainBaseline.new.greet(name: 'World') }
  x.report('rewritten')        { RewrittenMethod.new.greet(name: 'World') }

  x.compare!
end
