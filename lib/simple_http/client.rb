module SimpleHttp
  class Client
    attr_accessor :uri, :headers, :http_method, :query

    def initialize(opts)
      raise 'URL must be present' unless opts[:url]
      raise 'http_method must be present' unless opts[:http_method]

      @uri = URI(opts[:url])
      @http_method = opts[:http_method]
      @headers = opts[:headers]
      @query = opts[:query]
    end

    def call
      enable_ssl
      set_headers
      http.request(request)
    end

    private

    def set_headers
      request["Accept"] = headers[:accept] if headers[:accept]
      request["Authorization"] = headers[:Authorization] if headers[:Authorization]
      request["Content-Type"] = headers[:content_type] if headers[:content_type]
      request["Cookie"] = headers[:cookie] if headers[:cookie]
    end

    def request
      @request ||= (http_method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri))
    end

    def enable_ssl
      return unless uri.scheme == 'https'

      http.use_ssl = true
      http.ssl_version = :TLSv1_2
    end

    def http
      @http ||= Net::HTTP.new(uri.host, uri.port)
    end
  end
end