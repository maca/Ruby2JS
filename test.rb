require 'rubygems'
require 'pp'
require 'ruby_parser'




"1 + (1 + (1 + (1 * (2 - 1))))"
s(:call, s(:lit, 1), :+, s(:arglist, s(:call, s(:lit, 1), :+, s(:arglist, s(:call, s(:lit, 1), :+, s(:arglist, s(:call, s(:lit, 1), :*, s(:arglist, s(:call, s(:lit, 2), :-, s(:arglist, s(:lit, 1)))))))))))
