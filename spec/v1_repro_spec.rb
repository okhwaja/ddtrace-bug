require "spec_helper"
require "rspec"
require "ddtrace"
require "datadog/opentracer"
require "rack/mock"

RSpec.describe "this fails on v1" do
  it "fails to propagate trace" do
    datadog_opentracer = Datadog::OpenTracer::Tracer.new(
      enabled: true,
      default_service: "my-service",
    )
    # set up the tracer
    OpenTracing.global_tracer = datadog_opentracer

    # start tracing
    scope = OpenTracing.start_active_span('my.span')
    og_span = scope.span

    # prepare to start a distributed trace
    headers = {}
    OpenTracing.inject(og_span.context, OpenTracing::FORMAT_RACK, headers)

    # testing hack - populate headers with HTTP_X prefixes into env so we can test extraction
    # x-datadog-trace-id --> HTTP_X_DATADOG_TRACE_ID
    env = Rack::MockRequest.env_for("http://localhost:8080/")
    headers.each do |name, val|
      env["http-#{name}".upcase!.tr('-', '_')] = val
    end

    # now on "remote host", try to extract context and continue the trace
    # now try to parse it
    incoming = Rack::Request.new(env)
    extracted_ctx = OpenTracing.extract(OpenTracing::FORMAT_RACK, incoming.env)

    # start a new remote span
    remote_span = OpenTracing.global_tracer.start_active_span('remote.span', child_of: extracted_ctx).span

    # not the same span
    expect(og_span.datadog_span.id).not_to eq(remote_span.datadog_span.id)
    # they are linked
    expect(og_span.datadog_span.id).to eq(remote_span.datadog_span.parent_id)
    expect(og_span.datadog_span.trace_id).to eq(remote_span.datadog_span.trace_id)

    # prepare to start another distributed trace
    headers2 = {}
    OpenTracing.inject(remote_span.context, OpenTracing::FORMAT_RACK, headers2) # <-- NoMethodError
  end

  it "works with the non-OpenTracer tracer" do
    Datadog.configure do |c|
      c.service = "my-service"
    end

    # start tracing
    og_span = Datadog::Tracing.trace('og.span')

    # prepare to start a distributed trace
    trace_digest = Datadog::Tracing.active_trace.to_digest
    headers = {}
    Datadog::Tracing::Propagation::HTTP.inject!(trace_digest, headers)

    # testing hack - populate headers with HTTP_X prefixes into env so we can test extraction
    # x-datadog-trace-id --> HTTP_X_DATADOG_TRACE_ID
    env = Rack::MockRequest.env_for("http://localhost:8080/")
    headers.each do |name, val|
      env["http-#{name}".upcase!.tr('-', '_')] = val
    end

    # now on "remote host", try to extract context and continue the trace
    # now try to parse it
    incoming = Rack::Request.new(env)
    extracted_ctx = Datadog::Tracing::Propagation::HTTP.extract(incoming.env)

    remote_span = Datadog::Tracing.trace('remote.span', continue_from: trace_digest)
    # confirm different spans
    expect(og_span.span_id).not_to eq(remote_span.span_id)

    # confirm they are linked
    expect(og_span.span_id).to eq(remote_span.parent_id)
    expect(og_span.trace_id).to eq(remote_span.trace_id)

    # prepare to start another distributed trace
    trace_digest = Datadog::Tracing.active_trace.to_digest
    headers2 = {}
    Datadog::Tracing::Propagation::HTTP.inject!(trace_digest, headers2) # <-- No issue
  end
end
