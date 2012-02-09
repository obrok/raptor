require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/responders"
require_relative "../lib/raptor/injector"

describe Raptor::PlaintextResponder do
  describe ".matches?" do
    it "matches if :text params given" do
      Raptor::PlaintextResponder.matches?({text: '1.9.3'}).should be_true
    end

    it "doesnt match if :text is not given" do
      Raptor::PlaintextResponder.matches?({}).should be_false
    end
  end
end

describe Raptor::RedirectResponder do
  before { Raptor.stub(:log) }

  let(:resource) do
    # XXX: #loldemeter
    routes = stub
    routes.stub(:route_named).with(:show).
      and_return(stub(:path => "/my_resource/:id"))
    routes.stub(:route_named).with(:index) { stub(:path => "/my_resource") }
    stub(:name => "my_resource", :routes => routes)
  end

  it "fills route variables with record methods" do
    response = redirect_to_action(:show, stub('record', :id => 1))
    response.status.should == 302
    response['Location'].should == "/my_resource/1"
  end

  it "redirects to routes without variables in them" do
    response = redirect_to_action(:index, stub('record'))
    response.status.should == 302
    response['Location'].should == "/my_resource"
  end

  describe ".matches?" do
    it "matches if :redirect key is given" do
      Raptor::RedirectResponder.matches?({redirect: '/some/path'}).should be_true
    end

    it "doesn't match if :redirect key is not given" do
      Raptor::RedirectResponder.matches?({}).should be_false
    end
  end

  def redirect_to_action(action, record)
    responder = Raptor::RedirectResponder.new(resource, action, {:redirect => action})
    injection_sources = {}
    response = responder.respond(record, injection_sources)
  end
end

describe Raptor::ActionTemplateResponder do
  it "renders templates" do
    resource = stub(:path_component => "posts",
                    :one_presenter => APresenter)
    responder = Raptor::ActionTemplateResponder.new(resource, :show, {present: :one})
    record = stub
    injector = Raptor::Injector.new({})
    Raptor::Template.stub(:render).with(APresenter.new, "posts/show.html.erb").
      and_return("it worked")
    response = responder.respond(record, injector)
    response.body.join.strip.should == "it worked"
  end

  describe ".matches?" do
    it "matches everything" do
      Raptor::ActionTemplateResponder.matches?({}).should be_true
    end
  end
end

describe Raptor::TemplateResponder do
  describe ".matches?" do
    it "matches if :render given" do
      Raptor::TemplateResponder.matches?(render: '/some/path')
    end

    it "doesn't match if :template_path given" do
      Raptor::TemplateResponder.matches?({})
    end
  end
end

class APresenter
  @@instance = new

  def self.new
    @@instance
  end
end

