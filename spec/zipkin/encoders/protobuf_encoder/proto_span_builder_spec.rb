require 'spec_helper'

RSpec.describe Zipkin::Encoders::ProtobufEncoder::ProtoSpanBuilder do
  let(:local_endpoint) do
    Zipkin::Endpoint.new(service_name: 'local', ipv4: '127.0.0.1')
  end
  let(:builder) { described_class.new(local_endpoint) }

  it 'encodes span trace_id as bytes' do
    trace_id = '34b4200a745a3b61'
    span = build_span(trace_id: trace_id)
    expect(span.trace_id.bytes).to eq([52, 180, 32, 10, 116, 90, 59, 97])
  end

  it 'encodes span parent_id as bytes' do
    parent_id = '34b4200a745a3b61'
    span = build_span(parent_id: parent_id)
    expect(span.parent_id.bytes).to eq([52, 180, 32, 10, 116, 90, 59, 97])
  end

  it 'encodes span id as bytes' do
    span_id = '34b4200a745a3b61'
    span = build_span(span_id: span_id)
    expect(span.id.bytes).to eq([52, 180, 32, 10, 116, 90, 59, 97])
  end

  describe '#kind' do
    it 'sets it to server when span.kind tag is set to server' do
      span = build_span(tags: { :'span.kind' => 'server' })
      expect(span.kind).to eq(Zipkin::Proto3::Span::Kind::SERVER)
    end

    it 'sets it to client when span.kind tag is set to client' do
      span = build_span(tags: { :'span.kind' => 'client' })
      expect(span.kind).to eq(Zipkin::Proto3::Span::Kind::CLIENT)
    end

    it 'sets it to producer when span.kind tag is set to producer' do
      span = build_span(tags: { :'span.kind' => 'producer' })
      expect(span.kind).to eq(Zipkin::Proto3::Span::Kind::PRODUCER)
    end

    it 'sets it to consumer when span.kind tag is set to consumer' do
      span = build_span(tags: { :'span.kind' => 'consumer' })
      expect(span.kind).to eq(Zipkin::Proto3::Span::Kind::CONSUMER)
    end

    it 'sets it to server when span.kind is unspecified' do
      span = build_span(tags: {})
      expect(span.kind).to eq(Zipkin::Proto3::Span::Kind::SERVER)
    end
  end

  it 'sets operation name' do
    operation_name = 'some operation name'
    span = build_span(operation_name: operation_name)
    expect(span.name).to eq(operation_name)
  end

  it 'sets local endpoint' do
    span = build_span
    expect(span.local_endpoint.service_name).to eq(local_endpoint.service_name)
    expect(span.local_endpoint.ipv4).to eq("\x7F\x00\x00\x01") # 127.0.0.1
  end

  def build_span(opts = {})
    span = Zipkin::Span.new(
      Zipkin::SpanContext.new(
        trace_id: opts.fetch(:trace_id, Zipkin::TraceId.generate),
        parent_id: opts.fetch(:parent_id, Zipkin::TraceId.generate),
        span_id: opts.fetch(:span_id, Zipkin::TraceId.generate),
        sampled: opts.fetch(:sampled, true)
      ),
      opts.fetch(:operation_name, 'test'),
      spy,
      tags: opts.fetch(:tags, {})
    )
    span.finish
    builder.build(span)
  end
end
