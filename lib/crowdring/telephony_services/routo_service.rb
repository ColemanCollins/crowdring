 module Crowdring
  class RoutoService < TelephonyService
    supports :sms
        
    def initialize(username, password, number)
      @user_name = username
      @password = password
      @number = number
    end

    def send_sms(params)
      uri = URI('https://smsc5.routotelecom.com/SMSsend')
      back_up_uri = URI('https://smsc6.routotelecom.com/SMSsend')

      encoded_params = encode_params(params)
      uri.query = encoded_params
      response = send_request(uri)
      if response.body == 'failed' || response.body == 'sys_error' || response.body == 'bad_operator'
        back_up_uri.query = encoded_params
        send_request(back_up_uri)
      end  
    end

    def numbers
      [@number]
    end

    def broadcast
      params = {key: @username, secret: @password}
      Resque.enqueue(RoutoBatchSendSms, params, from, msg, to_numbers)
    end

    private 

    def encode_params(params)
      to = params[:to].sub('+','')
      from = params[:from].sub('+','')
      message = params[:msg]
      
      params={ number: to, user: @user_name, pass: @password, message: message, ownnum: from}
      URI.encode_www_form(params)
    end

    def send_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      http.request(request)
    end
  end
end
