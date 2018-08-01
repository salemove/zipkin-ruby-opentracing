# rubocop:disable all
# encoding: utf-8

##
# This file is auto-generated. DO NOT EDIT!
#
require 'protobuf'

module Zipkin
  module Proto3
    ::Protobuf::Optionable.inject(self) { ::Google::Protobuf::FileOptions }

    ##
    # Message Classes
    #
    class Span < ::Protobuf::Message
      class Kind < ::Protobuf::Enum
        define :SPAN_KIND_UNSPECIFIED, 0
        define :CLIENT, 1
        define :SERVER, 2
        define :PRODUCER, 3
        define :CONSUMER, 4
      end

    end

    class Endpoint < ::Protobuf::Message; end
    class Annotation < ::Protobuf::Message; end
    class ListOfSpans < ::Protobuf::Message; end


    ##
    # File Options
    #
    set_option :java_package, "zipkin2.proto3"
    set_option :java_multiple_files, true


    ##
    # Message Fields
    #
    class Span
      optional :bytes, :trace_id, 1
      optional :bytes, :parent_id, 2
      optional :bytes, :id, 3
      optional ::Zipkin::Proto3::Span::Kind, :kind, 4
      optional :string, :name, 5
      optional :fixed64, :timestamp, 6
      optional :uint64, :duration, 7
      optional ::Zipkin::Proto3::Endpoint, :local_endpoint, 8
      optional ::Zipkin::Proto3::Endpoint, :remote_endpoint, 9
      repeated ::Zipkin::Proto3::Annotation, :annotations, 10
      map :string, :string, :tags, 11
      optional :bool, :debug, 12
      optional :bool, :shared, 13
    end

    class Endpoint
      optional :string, :service_name, 1
      optional :bytes, :ipv4, 2
      optional :bytes, :ipv6, 3
      optional :int32, :port, 4
    end

    class Annotation
      optional :fixed64, :timestamp, 1
      optional :string, :value, 2
    end

    class ListOfSpans
      repeated ::Zipkin::Proto3::Span, :spans, 1
    end

  end

end

