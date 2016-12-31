begin
  require 'bundler'
  Bundler.require

  if ENV['COVERAGE']
    require 'simplecov'
    SimpleCov.start do
      add_filter '/test/'
      add_filter '/vendor/'
    end
  end
rescue LoadError
end

require 'test/unit'
require 'power_assert'
require 'ripper'

module PowerAssertTestHelper
  class << self
    def included(base)
      base.extend(ClassMethods)
    end
  end

  module ClassMethods
    def t(msg='', &blk)
      loc = caller_locations(1, 1)[0]
      test("#{loc.path} --location #{loc.lineno} #{msg}", &blk)
    end
  end

  private

  def _test_extract_methods((expected_idents, expected_paths, source))
    pa = ::PowerAssert.const_get(:Context).new(-> { var = nil; -> { var } }.(), nil, TOPLEVEL_BINDING)
    pa.instance_variable_set(:@line, source)
    pa.instance_variable_set(:@assertion_method_name, 'assertion_message')
    idents = pa.send(:extract_idents, Ripper.sexp(source))
    assert_equal expected_idents, map_recursive(idents, &:to_a), source
    if expected_paths
      assert_equal expected_paths, map_recursive(pa.send(:collect_paths, idents), &:name), source
    end
  end

  def map_recursive(ary, &blk)
    ary.map {|i| Array === i ? map_recursive(i, &blk) : yield(i) }
  end

  def assertion_message(source = nil, source_binding = TOPLEVEL_BINDING, &blk)
    ::PowerAssert.start(source || blk, assertion_method: __callee__, source_binding: source_binding) do |pa|
      pa.yield
      pa.message
    end
  end
end
