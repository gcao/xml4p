require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

SIMPLE_XML = <<-XML
<root>
<elem name='elem1' attr='attrvalue1'>1</elem>
<elem name='elem2' attr='attrvalue2'>2</elem>
</root>
XML

%w(libxml rexml).each do |xml_lib_name|
  load File.expand_path(File.dirname(__FILE__) + "/../../lib/xml4p/wrapper_for_#{xml_lib_name}.rb")
  
  @xml_lib_name = xml_lib_name
  
  def libxml?
    @xml_lib_name == 'libxml'
  end
  
  def rexml?
    @xml_lib_name == 'rexml'
  end 
  
  describe XML4P::Wrapper, "for #{xml_lib_name}" do

    describe "initialize" do

      it "can take a string" do
        XML4P::Wrapper.new(SIMPLE_XML)
      end

      it "can take an element" do
        if libxml?
          XML4P::Wrapper.new(LibXML::XML::Document.string('<root></root>').root)
        else
          XML4P::Wrapper.new(REXML::Document.new('<root></root>').root)
        end
      end

      it "should throw error on other parameter" do
        lambda {XML4P::Wrapper.new(123)}.should raise_error(ArgumentError)
      end

      it "should strip white spaces on input" do
        XML4P::Wrapper.new(" <root></root>  ").instance_variable_get(:'@input').should == '<root></root>'
      end

      it "should not strip white spaces on input if input is frozen" do
        s = " <root></root>  ".freeze
        XML4P::Wrapper.new(s).instance_variable_get(:'@input').should == s
      end

    end

    describe "find" do
      it "returns a list of wrapped elements" do
        wrapper = XML4P::Wrapper.new(SIMPLE_XML)
        result = wrapper.find('/root/elem')
        result.size.should == 2
        result[0].class.should == XML4P::Wrapper
      end

      it "xpath with attribute comparison" do
        wrapper = XML4P::Wrapper.new(SIMPLE_XML)
        wrapper.find("//elem[@name='elem1']")[0].content.should == '1'
      end
    end

    describe "first" do
      it "returns wrapped first match" do
        wrapper = XML4P::Wrapper.new(SIMPLE_XML)
        result = wrapper.first('/root/elem')
        result.class.should == XML4P::Wrapper
        result.content.should == '1'
      end

      it "returns nil if no match" do
        wrapper = XML4P::Wrapper.new(SIMPLE_XML)
        wrapper.first('/root/bad_elem').should be_nil
      end

      it "xpath with attribute comparison" do
        wrapper = XML4P::Wrapper.new(SIMPLE_XML)
        wrapper.first("//elem[@name='elem1']").content.should == '1'
      end
    end
    
    describe "first_with_attribute" do
      it "returns wrapped first element that matches xpath, attribute name and attribute value" do
        wrapper = XML4P::Wrapper.new(SIMPLE_XML)
        wrapper.first_with_attribute("//elem", 'name', 'elem1').content.should == '1'
      end
    end

    describe "attribute" do
      it "returns value of attribute" do
        wrapper = XML4P::Wrapper.new(SIMPLE_XML)
        wrapper.first("//elem[@name='elem1']").attribute('attr').should == 'attrvalue1'
      end
    end

    describe "content" do
      it "returns content for first match" do
        wrapper = XML4P::Wrapper.new(SIMPLE_XML)
        wrapper.content('/root/elem').should == '1'
      end

      it "returns nil if no match is found" do
        wrapper = XML4P::Wrapper.new(SIMPLE_XML)
        wrapper.content('/root/bad_elem').should be_nil
      end
    end

    describe "content=" do
      it "sets content for current element" do
        wrapper = XML4P::Wrapper.new("<root></root>")
        wrapper.content = "abc"
        wrapper.content.should == "abc"
        wrapper.to_s.should == "<root>abc</root>"
      end
    end

    describe "contents" do
      it "returns contents for matches" do
        wrapper = XML4P::Wrapper.new(SIMPLE_XML)
        wrapper.contents('/root/elem').should == ['1', '2']
      end

      it "returns [] if no match is found" do
        wrapper = XML4P::Wrapper.new(SIMPLE_XML)
        wrapper.contents('/root/bad_elem').should == []
      end
    end

    describe "valid?" do
      it "returns true if xml is valid" do
        wrapper = XML4P::Wrapper.new("<root></root>")
        wrapper.valid?.should be_true
      end

      it "returns false if xml is invalid" do
        wrapper = XML4P::Wrapper.new("root></root>")
        wrapper.valid?.should be_false
      end
    end

    describe "to_xml" do
      it "returns xml for element or document" do
        wrapper = XML4P::Wrapper.new("<root></root>")
        wrapper.to_xml.should == "<root/>"
      end
    end

    describe "to_hash" do
      it "should create a recursive hash of the xml document" do
        input =<<-XML
        <a>
        <b>
        <c>Foo</c>
        <d></d>
        <e/>
        </b>
        </a>  
        XML
        
        if libxml?
          expected_hash = { :a => { :b => { :c => 'Foo', :d => '', :e => '' } } }
        else
          expected_hash = { :a => { :b => { :c => 'Foo', :d => nil, :e => nil } } }
        end

        XML4P::Wrapper.new(input).to_hash.should == expected_hash
      end
    end

    describe "to_s" do
      it "returns xml for element or document" do
        wrapper = XML4P::Wrapper.new("<root></root>")
        wrapper.to_s.should == "<root/>"
      end
    end

    describe "with namespace" do
      before :each do
        @wrapper = XML4P::Wrapper.new <<-XML
        <root xmlns='http://www.vonage.com' xmlns:p='http://www.test.com'>
        <p:elem name='elem1' attr='attrvalue1'>1</p:elem>
        <p:elem name='elem2' attr='attrvalue2'>2</p:elem>
        <elem_with_default_ns>value</elem_with_default_ns>
        </root>
        XML
      end

      it "find should return elements with namespace" do
        @wrapper.find("//p:elem", "p:http://www.test.com").size.should == 2
      end

      it "find should return elements with default namespace" do
        @wrapper.find("//elem_with_default_ns", "http://www.test.com").size.should == 1
      end

      it "first should return first element with namespace" do
        @wrapper.first("//p:elem", "p:http://www.test.com").should_not be_nil
      end
      
      it "first_with_attribute should return first element with attribute and namespace" do
        @wrapper.first_with_attribute("//p:elem", 'name', 'elem1', "p:http://www.test.com").should_not be_nil
      end

      it "content should return content for first match" do
        @wrapper.content("//p:elem", "p:http://www.test.com").should == '1'
      end

      it "contents should return contents for matches" do
        @wrapper.contents("//p:elem", "p:http://www.test.com").should == ['1', '2']
      end
    end
  end
end
