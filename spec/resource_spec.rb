require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"
require_relative "fake_resources"

describe Raptor::Resource do
  let(:camel_case_resource) do
    Raptor::Resource.new(stub(:name => 'CamelCase'))
  end
  let(:resource) { Raptor::Resource.new(FakeResources::Post) }

  it "knows resources' names" do
    camel_case_resource.resource_name.should == 'CamelCase'
  end

  it "knows resources' path components" do
    camel_case_resource.path_component.should == 'camel_case'
  end

  it "knows how to get the record class" do
    resource.class_named(:Record).should == FakeResources::Post::Record
  end

  it "knows how to get the one presenter" do
    resource.one_presenter.should == FakeResources::Post::PresentsOne
  end

  it "knows how to get the many presenter" do
    resource.many_presenter.should == FakeResources::Post::PresentsMany
  end

  it "knows the requirements" do
    resource.requirements.should == [FakeResources::Post::LoggedInRequirement]
  end

  it "knows the module path" do
    resource.module_path.should == "FakeResources::Post"
  end
end

