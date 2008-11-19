# Handle several romanization systems for Mandarin Chinese
#
# Author::     Arne Brasseur (pinyin@arnebrasseur.net)
# Copyright::  Copyright (c) 2007, Arne Brasseur
# Licence::    GNU General Public License, latest version

$: << File.dirname(__FILE__)

require "facets/string/camelcase"

require 'pinyin/support'
require 'pinyin/groundwork'
require 'pinyin/exception'

require 'pinyin/tones'
require 'pinyin/conversion'
require 'pinyin/conversions'
require 'pinyin/conversions/hanyu'

module Pinyin
  VERSION = "0.1.5"

  class Reader
    def initialize(conv, tone)
      @conv = conv.to_s
      @tone = Tones.const_get tone.to_s.camelcase
    end

    def parse(str)
      Conversions.tokenize(str).map do |s, pos|
        tone,syll = @tone.pop_tone(s)
        tsyll = Conversions.parse(@conv,syll)
        ini, fin = tsyll.initial, tsyll.final
        unless tone && fin && ini
          raise ParseError.new(s,pos),"Illegal syllable <#{s}> in input <#{str}> at position #{pos}." 
        end
        Syllable.new(ini, fin, tone)
      end
    rescue Object => e
      raise ParseError.new(str,0), "Parsing of #{str.inspect} failed : #{e}"
    end

    alias :<< :parse
  end

  class Writer
    def initialize(conv, tone)
      @conv = conv.to_s
      @tone = Tones.const_get tone.to_s.camelcase
    end

    def unparse(py)
      conv=lambda {|syll| @tone.add_tone(Conversions.unparse(@conv,syll),syll.tone)}
      if py.respond_to? :map
        py.map(&conv).join(' ')
      else
        conv.call(py)
      end
    end

    alias :<< :unparse
  end

  class Converter
    def initialize(from, from_tone, to, to_tone)
      @reader = Reader.new(from, from_tone)
      @writer = Writer.new(to, to_tone)
    end

    def convert(str)
      @writer.unparse @reader.parse(str)
    end

    alias :<< :convert
  end
  
  class <<self
    Conversions::All.each do |c|
      define_method "#{c.to_s.camelcase}Reader" do |tone|
        Reader.new(c, tone)
      end

      define_method "#{c.to_s.camelcase}Writer" do |tone|
        Writer.new(c, tone)
      end
    end
  end
end


