module Raptor
  class PlaintextResponder
    def initialize(app_module, parent_path, params)
      @text = params[:text]
    end

    def self.matches?(params)
      params.has_key?(:text)
    end

    def respond(route, subject, injector)
      Rack::Response.new(@text)
    end
  end

  class ActionRedirectResponder
    def initialize(app_module, parent_path, params)
      @app_module = app_module
      @target = params[:redirect]
    end

    def self.matches?(params)
      params.has_key?(:redirect)
    end

    def respond(route, subject, injector)
      path = resource_path(route, subject)
      RedirectResponder.new(path).respond(route, subject, injector)
    end

    def resource_path(route, subject)
      path = route.neighbor_named(@target).path
      if subject
        path = path.gsub(/:\w+/) do |match|
          # XXX: Untrusted send
          subject.send(match.sub(/^:/, '')).to_s
        end
      end
      path
    end
  end

  class RedirectResponder
    def initialize(location)
      @location = location
    end

    def self.matches?(params)
      params[:redirect].kind_of?(String)
    end

    def respond(route, subject, injector)
      response = Rack::Response.new
      Raptor.log("Redirecting to #{@location}")
      response.status = 302
      response["Location"] = @location
      response
    end
  end

  class TemplateResponder
    def initialize(app_module, parent_path, params)
      @app_module = app_module
      @presenter_name = params[:present].to_s
      @template_path = params[:render]
      @path = parent_path
    end

    def self.matches?(params)
      params.has_key?(:render)
    end

    def respond(route, subject, injector)
      presenter = create_presenter(subject, injector)
      Rack::Response.new(render(presenter))
    end

    def render(presenter)
      layout = FindsLayouts.find(@path)
      template = Template.from_path(presenter, template_path)
      layout.render(template)
    end

    def template_path
      "#{@template_path}.html.erb"
    end

    def create_presenter(subject, injector)
      injector = injector.add_subject(subject)
      injector.call(presenter_class.method(:new))
    end

    def presenter_class
      constant_name = Raptor::Util.camel_case(@presenter_name)
      @app_module::Presenters.const_get(constant_name)
    end
  end

  class ActionTemplateResponder
    def initialize(app_module, parent_path, params)
      @app_module = app_module
      @parent_path = parent_path
      @presenter_name = params[:present]
      @template_name = params[:action]
    end

    def self.matches?(params)
      true
    end

    def respond(route, subject, injector)
      responder = TemplateResponder.new(@app_module,
                                        @parent_path,
                                        {:present => @presenter_name, :render => template_path})
      responder.respond(route, subject, injector)
    end

    def template_path
      # XXX: Support multiple template directories
      "#{@parent_path}/#{@template_name}"
    end
  end

end

