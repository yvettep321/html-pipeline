# frozen_string_literal: true

require 'test_helper'
require 'helpers/mocked_instrumentation_service'

class HTML::PipelineTest < Minitest::Test
  Pipeline = HTML::Pipeline
  class TestFilter
    def self.call(input, context: {}, result: {}) # rubocop:disable Lint/UnusedMethodArgument
      input.reverse
    end
  end

  def setup
    @default_context = {}
    @result_class = Hash
    @pipeline = Pipeline.new [TestFilter], default_context: @default_context, result_class: @result_class
  end

  def test_filter_instrumentation
    service = MockedInstrumentationService.new
    events = service.subscribe 'call_filter.html_pipeline'
    @pipeline.instrumentation_service = service
    body = 'hello'
    @pipeline.call(body)
    event, payload, = events.pop
    assert event, 'event expected'
    assert_equal 'call_filter.html_pipeline', event
    assert_equal TestFilter.name, payload[:filter]
    assert_equal @pipeline.class.name, payload[:pipeline]
    assert_equal body.reverse, payload[:result][:output]
  end

  def test_pipeline_instrumentation
    service = MockedInstrumentationService.new
    events = service.subscribe 'call_pipeline.html_pipeline'
    @pipeline.instrumentation_service = service
    body = 'hello'
    @pipeline.call(body)
    event, payload, = events.pop
    assert event, 'event expected'
    assert_equal 'call_pipeline.html_pipeline', event
    assert_equal @pipeline.filters.map(&:name), payload[:filters]
    assert_equal @pipeline.class.name, payload[:pipeline]
    assert_equal body.reverse, payload[:result][:output]
  end

  def test_default_instrumentation_service
    service = 'default'
    Pipeline.default_instrumentation_service = service
    pipeline = Pipeline.new [], default_context: @default_context, result_class: @result_class
    assert_equal service, pipeline.instrumentation_service
  ensure
    Pipeline.default_instrumentation_service = nil
  end

  def test_setup_instrumentation
    assert_nil @pipeline.instrumentation_service

    service = MockedInstrumentationService.new
    events = service.subscribe 'call_pipeline.html_pipeline'
    name = 'foo'
    @pipeline.setup_instrumentation name, service: service

    assert_equal service, @pipeline.instrumentation_service
    assert_equal name, @pipeline.instrumentation_name

    body = 'foo'
    @pipeline.call(body)

    event, payload, = events.pop
    assert event, 'expected event'
    assert_equal name, payload[:pipeline]
    assert_equal body.reverse, payload[:result][:output]
  end
end
