require 'ruby_parser'
require 'pp'

$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

class RubyToJs
  VERSION = '0.0.1'
  
  def initialize( sexp )
    @assigns = []
    @sexp    = sexp
  end
  
  def to_js
    parse @sexp
  end

  protected
  def parse sexp

    # pp sexp
    return sexp unless sexp.kind_of? Array
    operand = sexp.shift

    case operand

    when :lit, :str
      lit = sexp.shift
      lit.is_a?( Numeric ) ? lit.to_s : lit.to_s.inspect
      
    when :lvar
      sexp.shift.to_s
      
    when :true, :false
      operand.to_s
      
    when :and
      "#{ parse [sexp.shift].unshift( :paren? ) } && #{ parse [sexp.shift].unshift( :paren? ) }"
    
    when :or
      "#{ parse [sexp.shift].unshift( :paren? ) } || #{ parse [sexp.shift].unshift( :paren? ) }"
    
    when :not
     "!#{ parse sexp.unshift( :paren? ) }"
      
    when :paren? # Injected
      sexp.flatten.size > 1 ? "(#{ parse sexp.shift })" : parse( sexp.shift )

    when :lasgn
      var    = mutate_name sexp.shift
      output = "#{ 'var ' unless @assigns.include? var }#{ var } = #{ parse sexp.shift }"
      @assigns << var
      output
      
    when :hash
      hashy = []
      hashy << [ parse( sexp.shift ), parse( sexp.shift ) ] until sexp.empty?
      "{#{ hashy.map{ |k,v| k << ' : ' << v }.join(',') }}"

    when :array
      "[#{ sexp.map{ |a| parse a }.join(', ') }]"

    when :block
      self.class.new( sexp.unshift( :group ) ).to_js

    when :group # Injected
      sexp.map{ |e| parse e }.join('; ')
      
    when :call
      receiver, method, args = sexp.shift, sexp.shift, sexp.shift
      case method
        
      when :[]
        raise 'parse error' unless receiver
        "#{ parse receiver }[#{ parse args }]"
      
      when :+, :-, :*, :/, :%
        raise "method call #{ method.inspect } expects an explicit receiver" unless receiver
        "#{ parse receiver } #{ method } #{ parse args }"
        
      else
        "#{ parse receiver }#{ '.' if receiver }#{ method }(#{ parse args })"
      end
      
    when :arglist
      sexp.map{ |e| parse e }.join(', ')
      
    when :masgn

      vars, values, output = sexp.shift[1..-1], sexp.shift[1..-1], []
      vars.each_with_index do |var, i| 
        output.push( var << values[i] )
      end
      parse output.unshift( :group )
    
    else 
      raise "unkonwn operand #{ operand.inspect }"
    end

  end
  
  def mutate_name( name )
    name
  end

end