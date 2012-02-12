require "rack"
require "spec_helper"
require "raptor"

module AModule; end

describe Raptor::Route do
  it "errors if redirect target doesn't exist"

  it "can render text" do
    route = Raptor::BuildsRoutes.new(AModule).root(:text => "the text")
    req = request("GET", "/posts")
    route.respond_to_request(req).body.join.strip.should == "the text"
  end

  it "routes to nested routes"
  it "tunnels PUTs over POSTs"
  it "tunnels DELETEs over POSTs"
  it "stores templates in templates directory, not views"
  it "allows overriding of the presenter class"
  it "uses consistent degelate terminology instead of sometimes calling them records"
  it "doesn't require .html.erb on template names"
  it "includes type definitions in routes so they can be casted before injection"
end

class MatchingRequirement
  def self.match?
    true
  end
end

