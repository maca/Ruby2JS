require 'sexp_processor'
require 'pp'

$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

class RubyToJs
  VERSION   = '0.0.1'
  LOGICAL   = :and, :not, :or
  BINARY    = :+, :-, :*, :/, :%
  OPERATORS = [[:*, :/, :%], [:+, :-]]
  
  def initialize( sexp, vars = [[]] )
    @sexp, @vars = sexp, vars.dup
  end
  
  def to_js
    parse( @sexp, nil )
  end
  
  protected
  def operator_index op
    OPERATORS.index( OPERATORS.find{ |el| el.include? op } ) || 1/0.0
  end
  
  def scope( sexp, vars, parent = nil )
    self.class.new( sexp, vars ).parse( sexp, parent )
  end

  def parse sexp, parent = nil, group = false
    return sexp unless sexp.kind_of? Array
    case operand = sexp.shift
      
    when *LOGICAL
      group = true if LOGICAL.include? parent
    
    when :call      
      method = sexp[1]
      proc   = s(:const, :Proc)
      
      if sexp.first == proc and method == :new
        sexp[0], sexp[1] = nil, :lambda
      elsif BINARY.include? method or method == :new
        operand = sexp.unshift.delete( method )
      end
      
    when :block
      @vars = [[], @vars]
      
    end
    
    output = handle operand, sexp, parent
    output = "(#{ output })" if group
    output
  end
  
  
  def handle operand, sexp, parent
    case operand

    when :lit, :str
      lit = sexp.shift
      lit.is_a?( Numeric ) ? lit.to_s : lit.to_s.inspect
      
    when :lvar, :const
      sexp.shift.to_s
      
    when :true, :false
      operand.to_s
      
    when :nil
      'null'
      
    when :and
      "#{ parse sexp.shift, operand } && #{ parse sexp.shift, operand }"
    
    when :or
      "#{ parse sexp.shift, operand } || #{ parse sexp.shift, operand }"
    
    when :not
     "!#{ parse sexp.shift, operand }"
      
    when :lasgn
      var    = mutate_name sexp.shift
      value  = parse sexp.shift
      output = value ? "#{ 'var ' unless @vars.flatten.include? var }#{ var } = #{ value }" : var
      @vars.first << var
      output
      
    when :hash
      hashy  = []
      hashy << [ parse( sexp.shift ), parse( sexp.shift ) ] until sexp.empty?
      "{#{ hashy.map{ |k,v| k << ' : ' << v }.join(',') }}"

    when :array
      "[#{ sexp.map{ |a| parse a }.join(', ') }]"

    when :block
      sexp.map{ |e| parse e }.join('; ')
      
    when *BINARY
      receiver, args = sexp.shift, sexp.shift
      op_index  = operator_index operand
      group     = receiver.first == :call && BINARY.include?( receiver[2] ) && op_index <= operator_index( receiver[2] )
      receiver  = "#{ parse receiver }"
      receiver  = "(#{ receiver })" if group
      
      if call = args.find_node(:call) 
        group_args = BINARY.include?( call[2] ) if op_index <= operator_index( call[2] )
      end
      
      args = parse args
      args = "(#{ args })" if group_args
      "#{ receiver } #{ operand } #{ args }"
 
      
    when :call
      receiver, method, args = sexp.shift, sexp.shift, sexp.shift
      return parse args if method == :lambda unless receiver
      case method
        
      when :[]
        raise 'parse error' unless receiver
        "#{ parse receiver }[#{ parse args }]"
        

        
      else
        "#{ parse receiver }#{ '.' if receiver }#{ method }(#{ parse args })"
      end
      
    when :arglist
      sexp.map{ |e| parse e }.join(', ')
      
    when :masgn
      if sexp.size == 1
        sexp    = sexp.shift
        sexp[0] = :arglist
        parse sexp
      else
        sexp.first[1..-1].zip sexp.last[1..-1] do |var, val|
          var << val
        end
        sexp = sexp.first
        sexp[0] = :block
        parse sexp
      end
    
    when :if
      condition    = parse sexp.shift
      true_block   = scope sexp.shift, @vars
      elseif       = parse( sexp.find_node( :if, true ), :if )
      else_block   = parse( sexp.shift )
      
      output       = "if (#{ condition }) {#{ true_block }}"
      output.sub!('if', 'else if') if parent == :if
      output << " #{ elseif }" if elseif
      output << " else {#{ else_block }}" if else_block
      output
      
    when :iter
      caller       = sexp.shift
      args         = sexp.shift
      function     = s(:function, args, sexp.shift)
      caller.last << function
      parse caller
    
    when :function
      "function(#{ parse sexp.shift }) {#{ scope sexp.shift, @vars }}"
      
    else 
      raise "unkonwn operand #{ operand.inspect }"
    end

  end
  
  def mutate_name( name )
    name
  end

end