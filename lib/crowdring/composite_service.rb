require 'singleton'

module Crowdring
  class CompositeService 
    include Singleton

    def initialize
      @services = {}
    end

    def add(name, service, is_default=false)
      @default_service = service if is_default
      @services[name] = service
    end

    def get(name)
      @services[name]
    end

    def extract_params(name, request)
      if @services.has_key? name
        @services[name].extract_params(request)
      else
        raise "No service handler installed at #{name}"
      end
    end

    def build_response(from, commands)
      supporting_service(from).build_response(from, commands)
    end

    def numbers
      @services.values.map(&:numbers).flatten
    end

    def send_sms(params)
      service = supporting_service(params[:from])
      if service.supports_outgoing?
        service.send_sms(params)
      else
        @default_service.send_sms(from: @default_service.numbers.first,
          to: params[:to], msg: params[:msg])
      end
    end

    private

    def supporting_service(number)
      service = @services.values.find {|s| supports_number(s, number)}
      if service.nil?
        raise "No service handler can handle #{number}"
      end
      service
    end

    def supports_number(service, number)
      service.numbers.include? number
    end
  end
end