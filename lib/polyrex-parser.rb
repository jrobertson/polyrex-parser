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
  
  private

  def parse(s)

    s.instance_eval{
      def fetch_summary()
        name = 'summary'
        self.slice(((self =~ /<#{name}>/) + name.length + 2) .. \
          (self =~ /<\/#{name}>/m) - 1) if self[/<#{name}>/]
      end
      def fetch_records()
        name = 'records'
        self.slice(((self =~ /<#{name}>/) + name.length + 2) .. \
          (self.rindex(/<\/#{name}>/m)) - 1) if self[/<#{name}>/]
      end
    }

    root_name, raw_attributes = s.match(/<(\w+)(\s[^\/>]+)?/).captures
    attributes = get_attributes(raw_attributes) if raw_attributes

    summary = RexleParser.new("<summary>#{s.fetch_summary}</summary>").to_a

    raw_records = s.fetch_records
    records = nil

    if raw_records then
      node_name = raw_records[/<(\w+)/,1]
      record_threads = raw_records.strip.split(/(?=<#{node_name}[^>]*>)/).map do |x| 
        Thread.new{ Thread.current[:record] = parse(x) }
      end
      records = record_threads.map{|x| x.join; x[:record]}
    end 

    [root_name, "", attributes, [*summary], ['records', "",{}, *records]]
  end

  def get_attributes(raw_attributes)
    raw_attributes.scan(/(\w+\='[^']+')|(\w+\="[^"]+")/).map(&:compact).flatten.inject({}) do |r, x|
      attr_name, val = x.split(/=/) 
      r.merge(attr_name => val[1..-2])
    end
  end  
  
end