Object.send(:remove_const, :XML4P) if defined? XML4P

require 'rexml/document'

module XML4P
  class Wrapper
    
    attr_reader :input
    
    def initialize(input)
      raise ArgumentError.new(input) unless [String, REXML::Element].include?(input.class)
      
      input.strip! if input.is_a? String and not input.frozen?
      @input = input
    end
    
    def find(xpath, namespace = nil)
      results = []
      REXML::XPath.each(element, xpath) {|elem| results << Wrapper.new(elem) }
      results
    end
    
    def first(xpath, namespace = nil)
      elem = REXML::XPath.first(element, xpath)
      elem ? Wrapper.new(elem) : nil
    end
    
    def first_with_attribute xpath, attr_name, attr_value, namespace = nil
      REXML::XPath.each(element, xpath) do |element|
        attribute = element.attribute(attr_name)
        return Wrapper.new(element) if attribute and attribute.value == attr_value
      end
      nil
    end
    
    def attribute(name)
      element.attributes[name]
    end
    
    def content(xpath = nil, namespace = nil)
      return element.text unless xpath
      
      found = REXML::XPath.first(element, xpath)
      found.text if found
    end
    
    def content= value
      element.text = value
    end
    
    def contents(xpath, namespace = nil)
      results = []
      REXML::XPath.each(element, xpath) {|elem| results << elem.text }
      results
    end
    
    def valid?
      begin
        not element.nil?
      rescue
        false
      end
    end
    
    def to_xml
      element.to_s
    end
    
    def to_hash
      { element.name.to_sym => build_hash_for(element) } 
    end
    
    def to_s
      to_xml
    end
  
    private
    
    def element
      return @element if @element
      
      if @input.class == String
        @element = REXML::Document.new(@input).root
      elsif @input.class == REXML::Element
        @element = @input
      end
    end
    
    def build_hash_for node
      children = []
      node.each_element { |e| children << e }
      if children.any?
        children.inject({}) do |hash, child|
          child_hash = build_hash_for child
          hash[child.name.to_sym] = child_hash
          hash
        end
      else
        node.text
      end
    end
  end
end