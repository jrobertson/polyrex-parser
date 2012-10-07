#!/usr/bin/ruby

# file: polyrex-parser.rb

require 'rexleparser'

class PolyrexParser

  def initialize(s)
    @a = parse(s)
  end
  
  def to_a()
    @a
  end
    
  def to_s()
    name, value, attributes, *remaining = @a
   [value.strip, scan_a(remaining)].flatten.join(' ')
  end
  
  private

  def scan_a(a)
    a.inject([]) do |r, x|
      name, value, attributes, *remaining = x
      text_remaining = scan_a remaining if remaining

      value = '' if name == 'format_mask' or name == 'schema' or name == 'recordx_type'
      r << value.strip << text_remaining if value
    end
  end
  
  def parse(s)
    s.instance_eval{
      def fetch_summary()
        name = 'summary'
        self.slice(((self =~ /<#{name}>/) + name.length + 2) .. \
          (self =~ /<\/#{name}>/m) - 1) if self[/<#{name}>/]
            end
            def fetch_records()
        name = 'records'
    
        result = ''

        if self[/<#{name}/] then
          result = self.slice(((self =~ /<#{name}/) + name.length + 2) .. \
            (self.rindex(/<\/#{name}>/m)) - 1) if self[/<\/#{name}/]
        end
        result
      end
    }

    result = s.match(/<(\w+)(\s[^\/>]+)?/)
    root_name, raw_attributes = result.captures if result
    puts 'result : '  + result.inspect
    attributes = get_attributes(raw_attributes) if raw_attributes
    raw_summary = s.fetch_summary

    summary = RexleParser.new("<summary>#{raw_summary}</summary>").to_a

    raw_records = s.fetch_records
    records = nil


    if raw_records and raw_records[/<\w+/] then

      puts 'raw_records : ' + raw_records.inspect
      node_name = raw_records[/<(\w+)/,1]

      #record_threads = raw_records.strip.split(/(?=<#{node_name}[^>]*>)/).map do |x| 

      a = []
      i = 0

      while i < raw_records.strip.length do
        i = scan_s(raw_records, node_name, i) + 1
        a << i
      end


      record_threads = ([0] + a).each_cons(2).map do |s1, s2|
        raw_s = raw_records[s1...s2]

        Thread.new{ Thread.current[:record] = parse(raw_s) }
      end
      records = record_threads.map{|x| x.join; x[:record]}

    end 

    [root_name, "", attributes ||= {}, [*summary], ['records', "",{}, *records]]

  end


  def scan_s(s, node_name, instances=0, i=0)

    r = s[i..-1] =~ /<\/?#{node_name}/
    l = node_name.length + 1
    return s.length if r.nil?

    if s.slice(i + r,l) == "<#{node_name}" then    
      scan_s(s, node_name, instances+1, i + r + l)
    else
      if instances > 1 then
        scan_s(s, node_name, instances - 1, i + r + node_name.length + 3)
      else
        return i + r + node_name.length + 2
      end
    end

  end
    
  def get_attributes(raw_attributes)    
    raw_attributes.scan(/(\w+\='[^']+')|(\w+\="[^"]+")/).map(&:compact).flatten.inject({}) do |r, x|
      attr_name, val = x.split(/=/) 
      r.merge(attr_name.to_sym => val[1..-2])
    end
  end    
end