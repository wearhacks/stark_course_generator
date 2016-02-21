#!/Users/nothing/.rvm/rubies/ruby-2.2.3/bin/ruby
module Starkgen

  require 'fileutils'
  require 'nokogiri'
  require 'cobravsmongoose'
  require 'json'
  require 'base64'
  require 'json/minify'
  
  REF = "_REF_" unless defined? REF
  
  HashTag = Struct.new(:hash, :tag, :card) # #nuggetz
  
  class Starkgen::XmlElements
    ELEMENTS = [MEDIA = "media", CODE = "code"]
  end

  class Starkgen::XmlAttributes
    ATTRIBUTES = [XSI = "xsi", SCHEMALOCATION = "@xsi:schemaLocation", 
      XMLNS = "@xmlns", SRC = "@src", TEST = "@test"]
  end


  # 0: Run XSD validation on the supplied XML (a.k.a. "Pass validation or GTFO")
  # -> returns a boolean value indicating whether there were any validation errors
  #    (prints 
  def Starkgen.validate(document_path, schema_path)
    return if !(check_file(schema_path) && check_file(document_path))
    schema = Nokogiri::XML::Schema(File.read(schema_path))
    raw_xml = File.open(document_path).read
    doc = Nokogiri::XML.parse(raw_xml)

    errors = schema.validate(doc)
    errors.each do |error|
      puts error.message
    end
    
    errors.empty? ? raw_xml : nil
  end


  # Take care of some special cases:
  #    - code: Take source code and put it where the attributes src/test are
  #    - media: Encode content to Base 64
  def Starkgen.process_course_definition(course)
    remove_unnecessary_attributes(course, 
      [nil, Starkgen::XmlAttributes::XSI, Starkgen::XmlAttributes::SCHEMALOCATION,
        Starkgen::XmlAttributes::XMLNS])
    post_process_elements(HashTag.new(course, nil))
  end
  
  

  private 


  # Inline referenced code files & encode pictures
  def Starkgen.post_process_elements(hashtag)
    stack = [hashtag]
    inlined = []

    while !stack.empty? do
      cur = stack.pop
      cur.hash.each do |k, v|
        if v.is_a?(String)
          replace_content(cur.tag, k, v, inlined)
        elsif v.is_a?(Hash)
          stack.push(HashTag.new(v, k))
        elsif v.is_a?(Array)
          v.each { |e| stack.push(HashTag.new(e, k)) if e.is_a?(Hash) }
        end
      end
    end

    hashtag
  end
  

  # Removes unnecessary attributes from the given XML hash
  # (could be XSD pointers, namespace declarations etc.)
  def Starkgen.remove_unnecessary_attributes(xml_hash, keys_to_remove)
    keys_to_remove.each do |k|
      recursive_delete(xml_hash, k)
    end
  end


  # Deep-remove the given key mapping from the given hash
  def Starkgen.recursive_delete(hash, to_remove)
    hash.delete(to_remove)
    hash.each_value do |value|
      if value.is_a? Hash
        recursive_delete(value, to_remove) 
      elsif value.is_a? Enumerable
        # Hashes could be nested inside arrays or whatever
        value.each do |c|
          recursive_delete(c, to_remove) if c.is_a? Hash
        end
      end
    end
  end
  
  
  # e.g. <media src="some path"/> 
  #      <code src="blink_template.ino" test="blink_test.cc"/>
  def Starkgen.replace_content(tag, attribute, value, inlined)
    case attribute
    when Starkgen::XmlAttributes::SRC, Starkgen::XmlAttributes::TEST
      case tag
      when Starkgen::XmlElements::MEDIA
        raise "wat" if attribute == Starkgen::XmlAttributes::TEST
        inline_file_content(value, inlined,
          lambda { |f, v| 
            v.concat(Base64.encode64(File.open(f, "rb").read)) 
          }
        )
      when Starkgen::XmlElements::CODE
        inline_file_content(value, inlined,
          lambda { |f, v| 
            File.foreach(f) { |line| v.concat(line) } 
          }
        )
      else
        raise "wat" # Yeah well it shouldn't even have passed XSD validation
                    # but putting this here in case the XSD gets changed
      end
    end
  end
  
  def Starkgen.inline_file_content(value, inlined, f)
    return if !check_file(value)
    filename = value.dup
    value.replace("{ \"name\": \"#{filename}\", \"content\": \"")
    if inlined.include?(filename)
      value.concat(Starkgen::REF)
    else
      f.call(filename, value)
      inlined.push(filename)
    end
    value.concat("\" }")
  end

  
  def Starkgen.check_file(path)
    file_exists = File.file?(path)
    if !file_exists
      puts "The source file " << path << " does not seem to exist..."
    end
    file_exists
  end
  
  
  # Send over the resulting structure to a repo
  def Starkgen.push_to_stark
    # TODO
  end


end


if ARGV.length != 2
  puts "----- Usage: starkgen foo.xml foo.json -----"
  exit
end

# TODO the XSD must be made internal
raw_xml = Starkgen::validate(ARGV.first, "maester.xsd") 
exit unless raw_xml
puts "Validation successful."

xml_hash = CobraVsMongoose.xml_to_hash(raw_xml)
Starkgen::process_course_definition(xml_hash)
  
# Write the final output
json = xml_hash.to_json
#json = JSON.minify(json)
File.open(ARGV.last, 'w+').write json
puts "... Generation complete."