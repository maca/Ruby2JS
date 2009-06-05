require 'rubygems'
require 'pp'
require 'ruby_parser'

# p RubyParser.new.parse( '1 + (1 + 1)' )

sexp = s(:arglist, s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))))
sexp.shift
# p sexp




sexp = s(:if, s(:true), 
    s(:lasgn, :a, s(:lit, 1)), 
    s(:if, s(:false), 
      s(:lasgn, :a, s(:lit, 2)), 
        s(:if, s(:or, s(:true), s(:false)), 
          s(:lasgn, :a, s(:lit, 3)), 
          s(:lasgn, :a, s(:lit, 4)))))
          
          

eifs = []
collect_eifs = lambda do |sexp|
  eif  = sexp.find_node( :if, true )
  eifs << eif
  collect_eifs.call( eif ) if eif
end

collect_eifs.call( sexp )

p eifs

# s(:if, s(:false), s(:lasgn, :a, s(:lit, 2)), s(:if, s(:or, s(:true), s(:false)), s(:lasgn, :a, s(:lit, 3)), s(:lasgn, :a, s(:lit, 4))))