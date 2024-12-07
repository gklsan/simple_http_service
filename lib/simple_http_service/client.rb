require 'net/http'
module SimpleHttpService
  class Client
    attr_accessor :uri, :headers, :http_method, :open_timeout, :read_timeout, :write_timeout,
                  :max_retries, :request_body, :additional_headers

    def initialize(opts)
      raise 'URL must be present' unless opts[:url]
      raise 'http_method must be present' unless opts[:http_method]

      @uri = URI(opts[:url])
      @http_method = opts[:http_method]
      @headers = opts[:headers] || {}
      @request_body = opts[:request_body]
      @open_timeout = opts[:open_timeout] || false
      @read_timeout = opts[:read_timeout] || false
      @write_timeout = opts[:write_timeout] || false
      @max_retries = opts[:max_retries] || 1
      @additional_headers = opts[:additional_headers] || {}
    end

    def call
      enable_ssl
      set_headers
      set_timeout
      http.request(request)
    end

    private

    def set_headers
      request["Accept"] = headers[:accept] if headers[:accept]
      request["Authorization"] = headers[:authorization] if headers[:authorization]
      request["Content-Type"] = headers[:content_type] if headers[:content_type]
      request["Cookie"] = headers[:cookie] if headers[:cookie]
      additional_headers.each {|key, value|  request[key] = value } if additional_headers
    end

    def request
      @request ||= case http_method
                   when :post
                     Net::HTTP::Post.new(uri)
                   when :put
                     Net::HTTP::Put.new(uri)
                   else
                     Net::HTTP::Get.new(uri)
                   end
    end

    def enable_ssl
      return unless uri.scheme == 'https'

      http.use_ssl = true
      http.ssl_version = :TLSv1_2
    end

    def set_timeout
      http.open_timeout = open_timeout if open_timeout
      http.read_timeout = read_timeout if read_timeout
      http.write_timeout = write_timeout if write_timeout
      http.max_retries = max_retries if max_retries
    end

    def set_request_params
      request.body = request_body if request_body.present?
    end

    def http
      @http ||= Net::HTTP.new(uri.host, uri.port)
    end
  end
end