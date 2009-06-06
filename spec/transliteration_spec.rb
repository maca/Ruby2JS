require  File.dirname( __FILE__ ) + '/spec_helper'
require 'ruby_parser'

describe RubyToJS do
  
  def rb_parse( string )
    RubyParser.new.parse string
  end
  
  def to_js( string)
    RubyToJS.new( rb_parse( string ) ).to_js
  end
  
  describe 'literals' do
    it "should parse literals and strings" do
      to_js( "1" ).should        == '1'
      to_js( "'string'" ).should == '"string"'
      to_js( ":symbol" ).should  == '"symbol"'
      to_js( "nil" ).should      == 'null'
      to_js( "Constant" ).should == 'Constant'
    end
    
    it "should parse simple hash" do
      to_js( "{}" ).should            == '{}'
      to_js( "{ :a => :b }" ).should  == '{"a" : "b"}'
    end
    
    it "should parse array" do
      to_js( "[]" ).should         == '[]'
      to_js( "[1, 2, 3]" ).should  == '[1, 2, 3]'
    end
    
    it "should parse nested hash" do
      to_js( "{ :a => {:b => :c} }" ).should  == '{"a" : {"b" : "c"}}'
    end
    
    it "should parse array" do
      to_js( "[1, [2, 3]]" ).should  == '[1, [2, 3]]'
    end
    
    it "should parse global variables" do
      to_js( "$a = 1" ).should == 'a = 1'
    end
  end
  
  describe 'assign' do
    it "should parse left assign" do
      to_js( "a = 1" ).should        == 'var a = 1'
      to_js( "a = 'string'" ).should == 'var a = "string"'
      to_js( "a = :symbol" ).should  == 'var a = "symbol"'
    end
    
    it "should not output var if variable is allready declared within a context" do
      to_js( "a = 1; a = 2" ).should == 'var a = 1; a = 2'
    end
    
    it "should parse mass assign" do
      to_js( "a , b = 1, 2" ).should == 'var a = 1; var b = 2'
    end
  end
  
  describe 'method call' do
    it "should parse method call with no args" do
      to_js( "a" ).should == 'a()'
    end
    
    it "should parse method call with args" do
      to_js( "a 1, 2, 3" ).should == 'a(1, 2, 3)'
    end
    
    it "should parse lvar as variable call" do
      to_js( "a = 1; a" ).should == 'var a = 1; a'
    end
    
    it "should parse square bracket call" do
      to_js( "a = [1]; a[0]" ).should == 'var a = [1]; a[0]'
    end
    
    it "should parse nested square bracket call" do
      to_js( "a = [[1]]; a[0][0]" ).should == 'var a = [[1]]; a[0][0]'
    end
    
    it "should parse binary operation" do
      to_js( "1 + 1" ).should == '1 + 1'
    end
    
    it "should call method on literal" do
      to_js( "[0][0]" ).should == '[0][0]'
    end
  end
  
  describe 'boolean' do
    it "should parse boolean" do
      to_js( "true; false" ).should    == 'true; false'
    end
    
    it "should parse logic operators" do
      to_js( "true && false" ).should  == 'true && false'
      to_js( "true and false" ).should == 'true && false'
      to_js( "true || false" ).should  == 'true || false'
      to_js( "true or false" ).should  == 'true || false'
    end
    
    it "should parse not" do
      to_js( "not true" ).should    == '!true'
    end
    
    it "should parse nested logic" do
      to_js( 'not (true or false)' ).should    == '!(true || false)'
    end
    
    it "should parse more complex nested logic" do
      logic = '!((true && false) || (false || false))'
      to_js( logic ).should == logic
    end
    
    it "should parse yet more complex nested logic" do
      logic = '!((true && (false && (true && true))) || (false || false))'
      to_js( logic ).should == logic
    end
  end
  
  describe 'expressions' do
    it "should not nest" do
      exp = '1 + 1 * 1'
      to_js( exp ).should == exp
    end
    
    it "should parse nested expressions" do
      exp = '(1 + 1) * 1'
      to_js( exp ).should == exp
    end
    
    it "should parse complex nested expressions" do
      exp = '1 + (1 + (1 + 1 * (2 - 1)))'
      to_js( exp ).should == exp
    end
    
    it "should parse complex nested expressions with method calls" do
      exp = '1 + (a() + (1 + 1 * (b() - d())))'
      to_js( exp ).should == exp
    end
    
    it "should parse complex nested expressions with method calls and variables" do
      exp = 'a = 5; 1 + (a + (1 + a * (b() - d())))'
      to_js( exp ).should == "var " << exp
    end
    
    it "should parse nested sender" do
      exp = '((1 / 2) * 4 - (1 + 1)) - 1'
      to_js( exp ).should == exp
    end
  end
  
  describe 'control' do
    it "should parse single line if" do
      to_js( '1 if true' ).should == 'if (true) {1}'
    end
    
    it "should parse if else" do
      to_js( 'if true; 1; else; 2; end' ).should == 'if (true) {1} else {2}'
    end
    
    it "should parse if elsif" do
      to_js( 'if true; 1; elsif false; 2; else; 3; end' ).should == 'if (true) {1} else if (false) {2} else {3}'
    end
    
    it "should parse if elsif elsif" do
      to_js( 'if true; 1; elsif false; 2; elsif (true or false); 3; else; nassif; end' ).should == 'if (true) {1} else if (false) {2} else if (true || false) {3} else {nassif()}' 
    end
    
    it "should handle basic variable scope" do
      to_js( 'a = 1; if true; a = 2; b = 1; elsif false; a = 3; b = 2; else; a = 4; b =3; end' ).should == 'var a = 1; if (true) {a = 2; var b = 1} else if (false) {a = 3; var b = 2} else {a = 4; var b = 3}'
    end
  end
  
  describe 'blocks' do
    it "should parse proc" do
      to_js('Proc.new {}').should == 'function() {}'
    end
    
    it "should parse lambda" do
      to_js( 'lambda {}').should == 'function() {}'
    end
    
    it "should handle basic variable scope" do
      to_js( 'a = 1; lambda { a = 2; b = 1}').should == 'var a = 1; function() {a = 2; var b = 1}'
    end
    
    it "should handle variable scope" do
      to_js( 'a = 1; lambda { a = 2; b = 1; lambda{ a = 3; b = 2; c = 1; lambda{ a = 4; b = 3; c = 2; d = 1 } } }').
        should == 'var a = 1; function() {a = 2; var b = 1; function() {a = 3; b = 2; var c = 1; function() {a = 4; b = 3; c = 2; var d = 1}}}'
    end
    
    it "should handle one argument" do
      to_js( 'lambda { |a| a + 1 }').should == 'function(a) {a + 1}'
    end
    
    it "should handle arguments" do
      to_js( 'lambda { |a,b| a + b }').should == 'function(a, b) {a + b}'
    end
    
    it "should pass functions" do
      to_js( 'run("task"){ |task| do_run task}').should == 'run("task", function(task) {do_run(task)})'
    end
    
    it "should really handle variable scope" do
      to_js('a = 1; lambda {|b| c = 0; a = b - c }; lambda { |b| c = 1; a = b + c }').
        should == 'var a = 1; function(b) {var c = 0; a = b - c}; function(b) {var c = 1; a = b + c}'
    end
    
    it "should really handle variable scope" do
      to_js('a, d = 1, 2; lambda {|b| c = 0; a = b - c * d}; lambda { |b| c = 1; a = b + c * d}').
        should == 'var a = 1; var d = 2; function(b) {var c = 0; a = b - c * d}; function(b) {var c = 1; a = b + c * d}'
    end
  end
end