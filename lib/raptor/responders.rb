require "erb"

module Raptor
  class PlaintextResponder
    def initialize(resource, action, params)
      @text = params[:text]
    end

    def self.matches?(params)
      params.has_key?(:text)
    end

    def respond(record, injector)
      Rack::Response.new(@text)
    end
  end

  class RedirectResponder
    def initialize(resource, action, params)
      @resource = resource
      @target_route_name = params[:redirect]
    end

    def self.matches?(params)
      params.has_key?(:redirect)
    end

    def respond(record, injector)
      response = Rack::Response.new
      path = @resource.routes.route_named(@target_route_name).path
      if record
        path = path.gsub(/:\w+/) do |match|
          # XXX: Untrusted send
          record.send(match.sub(/^:/, '')).to_s
        end
      end
      redirect_to(response, path)
      response
    end

    def redirect_to(response, location)
      Raptor.log("Redirecting to #{location}")
      response.status = 302
      response["Location"] = location
    end
  end

  class TemplateResponder
    def initialize(resource, action, params)
      @resource = resource
      @presenter_name = params[:present]
      @template_path = params[:render]
    end

    def self.matches?(params)
      params.has_key?(:render)
    end

    def respond(record, injector)
      presenter = create_presenter(record, injector)
      Rack::Response.new(render(presenter))
    end

    def render(presenter)
      Template.render(presenter, template_path)
    end

    def template_path
      "#{@template_path}.html.erb"
    end

    def create_presenter(record, injector)
      injector = injector.add_record(record)
      injector.call(presenter_class.method(:new))
    end

    def presenter_class
      @resource.send("#{@presenter_name}_presenter")
    end
  end

  class ActionTemplateResponder
    def initialize(resource, action, params)
      @resource = resource
      @presenter_name = params[:present]
      @template_name = action
    end

    def self.matches?(params)
      true
    end

    def respond(record, injector)
      responder = TemplateResponder.new(@resource,
                                        @template_name,
                                        {:present => @presenter_name, :render => template_path})
      responder.respond(record, injector)
    end

    def template_path
      "#{@resource.path_component}/#{@template_name}"
    end
  end

  class Template
    def initialize(presenter, template_path)
      @presenter = presenter
      @template_path = template_path
    end

    def self.render(presenter, template_path)
      new(presenter, template_path).render
    end

    def render
      template.result(@presenter.instance_eval { binding })
    end

    def template
      ERB.new(File.new(full_template_path).read)
    end

    def full_template_path
      "views/#{@template_path}"
    end
  end
end

