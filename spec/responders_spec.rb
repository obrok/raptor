require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"

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
  describe ".matches?" do
    it "matches if a String :redirect is given" do
      Raptor::RedirectResponder.matches?({:redirect => "/some/path"}).should be_true
    end

    it "doesn't match if something else is given" do
      Raptor::RedirectResponder.matches?({:redirect => :show}).should be_false
    end
  end
end

describe Raptor::ActionRedirectResponder do
  before { Raptor.stub(:log) }

  let(:app_module) { stub(:app_module) }

  let(:route) do
    route = stub
    route.stub(:neighbor_named).with(:show).
      and_return(stub(:path => "/my_resource/:id"))
    route.stub(:neighbor_named).with(:index).
      and_return(stub(:path => "/my_resource"))
    route
  end

  it "fills route variables with record methods" do
    response = redirect_to_action(:show, stub('record', :id => 1))
    response.should redirect_to('/my_resource/1')
  end

  it "redirects to routes without variables in them" do
    response = redirect_to_action(:index, stub('record'))
    response.should redirect_to('/my_resource')
  end

  describe ".matches?" do
    it "matches if :redirect key is given" do
      Raptor::ActionRedirectResponder.matches?({:redirect => :show}).should be_true
    end

    it "doesn't match if :redirect key is not given" do
      Raptor::ActionRedirectResponder.matches?({}).should be_false
    end
  end

  def redirect_to_action(action, record)
    responder = Raptor::ActionRedirectResponder.new(app_module, "posts", {:redirect => action})
    response = responder.respond(route, record, Raptor::Injector.new)
  end
end

describe Raptor::ActionTemplateResponder do
  it "renders templates" do
    app_module = Module.new
    app_module::Presenters = Module.new
    app_module::Presenters::Post = PostPresenter
    responder = Raptor::ActionTemplateResponder.new(app_module, 'posts', {:action => :show, :present => 'post'})
    record = stub
    route = stub
    injector = Raptor::Injector.new([])
    Raptor::Template.stub(:from_path).with(PostPresenter.new, "posts/show.html.erb")
    layout = stub(:layout)
    layout.stub(:render) { "it worked" }
    Raptor::FindsLayouts.stub(:find).with('posts') { layout }
    response = responder.respond(route, record, injector)
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

class PostPresenter
  @@instance = new

  def self.new
    @@instance
  end
end

