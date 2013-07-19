require 'spec_helper'

describe Swrve do

  subject { Swrve }
  let(:event_sender) { mock('event_sender') }
  let(:resource_getter) { mock('resource_getter') }
  let(:cache) { mock('cache') }

  before do
    Swrve::Api::Events.stubs(new: event_sender)
    Swrve::Api::Resources.stubs(new: resource_getter)
    Swrve::Middleware::Cache.any_instance.stubs(client: cache)
    Swrve.configure 
  end

  describe ".config" do
    it 'is a configuration' do
      Swrve.config.should be_a(Swrve::Configuration)
    end

    it 'responds to required configurations' do
      [:ab_test_url, :api_url, :web_app_version, :api_key, :local_resource_path, :game_id, :debug_url,
       :load_local_resources, :debug, :http_adapter].map do |value|
        Swrve.config.respond_to?(value)
      end.uniq.should == [true]
    end
  end

  describe '.configure' do

    before { Swrve.configure { |config| config.web_app_version = '11' }}

    it 'should be configurable' do
      Swrve.config.web_app_version.should == '11'
    end

  end

  it "has a version" do
    Swrve::VERSION.should be_a(String)
  end

  describe 'methods_delegated to event_sender' do
    @delegated_events = [
      :session_start, :session_end, :custom_event,
      :purchase, :buy_in, :currency_given, :update_user
    ]

    @delegated_events.each do |event|
      specify { subject.should respond_to(event) }

      it "send the #{event} request to the resources endpoint" do
        event_sender.expects(event)

        subject.send(event)
      end
    end
  end

  describe 'methods_delegated to resource_getter' do
    @delegated_events = [:resource, :resource_diff]

    @delegated_events.each do |event|
      specify { subject.should respond_to(event) }

      it "send the #{event} request to the resources endpoint" do
        resource_getter.expects(event)

        subject.send(event)
      end
    end
  end
end
