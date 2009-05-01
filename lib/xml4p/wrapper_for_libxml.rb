Object.send(:remove_const, :XML4P) if defined? XML4P

require 'libxml'

module XML4P
  class Wrapper
    include LibXML::XML
    
    attr_reader :input
    
    def initialize(input)
      raise ArgumentError.new(input) unless [String, Node].include?(input.class)
      
      input.strip! if input.is_a? String and not input.frozen?
      @input = input
    end
    
    def find(xpath, namespace = nil)
      element.find(xpath, namespace).map {|elem| Wrapper.new(elem) }
    end
    
    def first(xpath, namespace = nil)
      elem = element.find_first(xpath, namespace)
      elem ? Wrapper.new(elem) : nil
    end
    
    def first_with_attribute xpath, attr_name, attr_value, namespace = nil
      element.find(xpath, namespace).each do |e|
        return Wrapper.new(e) if e.attributes[attr_name] == attr_value
      end
      nil
    end
    
    def attribute(name)
      element.attributes[name]
    end
    
    def content(xpath = nil, namespace = nil)
      return element.content unless xpath
      
      found = element.find_first(xpath, namespace)
      found.content if found
    end
    
    def content= value
      element.content = value
    end
    
    def contents(xpath, namespace = nil)
      element.find(xpath, namespace).map {|elem| elem.content }
    end
    
    def valid?
      return true if not @element.nil?

      Error.set_handler(&Error::QUIET_HANDLER)
      @element = Document.string(@input).root
      Error.reset_handler
      !@element.nil?
    rescue Error
      false
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
        @element = Document.string(@input).root
      elsif @input.class == Node
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
        node.content
      end
    end
  end
end