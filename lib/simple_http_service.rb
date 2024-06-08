require 'simple_http_service/version'
require 'simple_http_service/client'

module SimpleHttpService
  def self.new(*args)
    Client.new(*args)
  end

  class Error < StandardError; end
end
