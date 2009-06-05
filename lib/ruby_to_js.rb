require 'sexp_processor'
require 'pp'

$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

class RubyToJs
  VERSION  = '0.0.1'
  LOGICAL  = :and, :not, :or
  BINARY   = :+, :-, :*, :/, :%
  
  def initialize( sexp )
    @sexp, @assigns = sexp, []
  end
  
  def to_js
    parse( @sexp )
  end

  protected
  def parse sexp, parent = nil    
    return sexp unless sexp.kind_of? Array
    operand = sexp.shift

    case operand
      
    when *LOGICAL
      return "(#{ handle operand, sexp, parent })"     if LOGICAL.include? parent
    
    when :call
      operand = sexp.unshift.delete( sexp[1] ) if BINARY.include? sexp[1]
      
    when :arglist
      if BINARY.include? parent
        if call = sexp.find_node(:call)
          return "(#{ handle operand, sexp, parent })" if BINARY.include? call[2]
        end
      end
    end
    
    handle operand, sexp, parent
  end
  
  
  def handle operand, sexp, parent
    case operand

    when :lit, :str
      lit = sexp.shift
      lit.is_a?( Numeric ) ? lit.to_s : lit.to_s.inspect
      
    when :lvar
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
      var       = mutate_name sexp.shift
      output    = "#{ 'var ' unless @assigns.include? var }#{ var } = #{ parse sexp.shift }"
      @assigns << var
      output
      
    when :hash
      hashy  = []
      hashy << [ parse( sexp.shift ), parse( sexp.shift ) ] until sexp.empty?
      "{#{ hashy.map{ |k,v| k << ' : ' << v }.join(',') }}"

    when :array
      "[#{ sexp.map{ |a| parse a }.join(', ') }]"

    when :block
      self.class.new( sexp.unshift( :expressions ) ).to_js

    when :expressions # Injected
      sexp.map{ |e| parse e }.join('; ')
      
    when *BINARY
      "#{ parse sexp.shift, operand } #{ operand } #{ parse sexp.shift, operand }"
      
    when :call
      receiver, method, args = sexp.shift, sexp.shift, sexp.shift
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
      vars, values, output = sexp.shift[1..-1], sexp.shift[1..-1], []
      vars.each_with_index do |var, i| 
        output.push( var << values[i] )
      end
      parse output.unshift( :expressions )
    
    when :if
      condition    = parse sexp.shift
      true_block   = parse sexp.shift
      elseif       = parse( sexp.find_node( :if, true ), :if )
      else_block   = parse( sexp.shift )
            
      output       = "if (#{ condition }) {#{ true_block }}"
      output.sub!('if', 'else if') if parent == :if
      output << " #{ elseif }" if elseif
      output << " else {#{ else_block }}" if else_block
      output
      
      
      
      

      
      
    else 
      raise "unkonwn operand #{ operand.inspect }"
    end

  end
  
  def mutate_name( name )
    name
  end

end