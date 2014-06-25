require 'optparse'
require 'java'
require 'stringio'
require 'nokogiri'
require 'opener/core'

require File.expand_path('../../../core/target/ehu-ned-1.0.jar', __FILE__)

require_relative 'ned/version'
require_relative 'ned/cli'

import 'java.io.InputStreamReader'

import 'ixa.kaflib.KAFDocument'

module Opener
  ##
  # Ruby wrapper around the Java based Ned tool that's powered by DBpedia.
  #
  # @!attribute [r] options
  #  @return [Hash]
  #
  class Ned
    attr_reader :options

    LANGUAGE_ENDPOINTS = {
      "en"=>"http://spotlight.sztaki.hu:2222",
      "nl"=>"http://nl.dbpedia.org/spotlight",
      "fr"=>"http://spotlight.sztaki.hu:2225",
      "de"=>"http://de.dbpedia.org/spotlight",
      "es"=>"http://spotlight.sztaki.hu:2231",
      "it"=>"http://spotlight.sztaki.hu:2230",
      "ru"=>"http://spotlight.sztaki.hu:2227",
      "pt"=>"http://spotlight.sztaki.hu:2228",
      "hu"=>"http://spotlight.sztaki.hu:2229",
      "tr"=>"http://spotlight.sztaki.hu:2235"
    }

    ##
    # Hash containing the default options to use.
    #
    # @return [Hash]
    #
    DEFAULT_OPTIONS = {
      :args    => [],
      :logging => false
    }.freeze

    ##
    # @param [Hash] options
    #
    # @option options [Array] :args Arbitrary arguments to pass to the
    #  underlying kernel.
    #
    # @option options [TrueClass|FalseClass] :logging When set to `true`
    #  logging is enabled. This is disabled by default.
    #
    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def run(input)
      begin
        if !input or input.strip.empty?
          raise ArgumentError, 'No input specified'
        end

        language = language_from_kaf(input)

        input_io  = StringIO.new(input)
        reader    = InputStreamReader.new(input_io.to_inputstream)
        document  = KAFDocument.create_from_stream(reader)
        annotator = Java::ehu.ned.Annotate.new

        annotator.disableLogging unless options[:logging]

        endpoint = options.fetch(:endpoint, uri_for_language(language))

        annotator.disambiguateNEsToKAF(
          document,
          endpoint.to_s
        )

        return document.to_string

      rescue Exception => error
        return Opener::Core::ErrorLayer.new(input, error.message, self.class).add
      end
    end

    private

    def language_from_kaf(input)
      document = Nokogiri::XML(input)
      language = document.at('KAF').attr('xml:lang')
    end

    def uri_for_language(language)
      LANGUAGE_ENDPOINTS[language]+"/rest/disambiguate"
    end

  end # Ned
end # Opener
