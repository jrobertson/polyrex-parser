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

    root_name = s[/<(\w+)/,1]

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

    [root_name, "", {}, [*summary], ['records', "",{}, *records]]
  end

end