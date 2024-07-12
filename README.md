# SimpleHttpService [![Gem Version](https://badge.fury.io/rb/simple_http_service.svg)](https://badge.fury.io/rb/simple_http_service)

SimpleHttpService is a simple Ruby library to make HTTP requests with customizable options for headers, timeouts, and retries. It provides a convenient way to create and send HTTP requests using a clean and simple interface.

## Installation

Add this line to your application's Gemfile:

    gem 'simple_http_service'

And then execute:

    bundle install

Or install it yourself as:

    gem install simple_http_service

## Usage

### Creating a Client
You can create a new HTTP client using the SimpleHttpService.new method, which initializes an instance of SimpleHttpService::Client.

```ruby
require 'simple_http_service'

client = SimpleHttpService.new(
  url: 'https://api.example.com/endpoint',
  http_method: :get,
  headers: {
    accept: 'application/json',
    authorization: 'Bearer your_token',
    content_type: 'application/json',
    cookie: 'your cookie'
  },
  open_timeout: 5,
  read_timeout: 10,
  write_timeout: 5,
  max_retries: 3
)
```
### Making a Request
After creating the client, you can call the call method to make the HTTP request:
```ruby
response = client.call
puts response.body
```

### Options
- `url` (required): The URL for the HTTP request.
- `http_method` (required): The HTTP method to use (:get, :post, :put).
- `headers`: A hash of headers to include in the request.
- `open_timeout`: Timeout for opening the connection (default is false).
- `read_timeout`: Timeout for reading the response (default is false).
- `write_timeout`: Timeout for writing the request (default is false).
- `max_retries`: The number of times to retry the request in case of failure.
- `request_body`: The body of the request (used for POST and PUT requests).

### Example
Here's a complete example of using `SimpleHttpService` to make a `GET` request:

```ruby
require 'simple_http_service'

client = SimpleHttpService.new(
  url: 'https://api.example.com/endpoint',
  http_method: :get,
  headers: {
    accept: 'application/json',
    authorization: 'Bearer your_token'
  },
  open_timeout: 5,
  read_timeout: 10
)

response = client.call
puts response.body
```
For a POST request with a request body:
```ruby
require 'simple_http_service'

client = SimpleHttpService.new(
  url: 'https://api.example.com/endpoint',
  http_method: :post,
  headers: {
    accept: 'application/json',
    authorization: 'Bearer your_token',
    content_type: 'application/json'
  },
  request_body: { key: 'value' }.to_json,
  open_timeout: 5,
  read_timeout: 10,
  write_timeout: 5
)

response = client.call
puts response.body
```

### Error Handling
The library defines a custom error class SimpleHttpService::Error that you can use to handle exceptions:
```ruby
begin
  response = client.call
  puts response.body
rescue SimpleHttpService::Error => e
  puts "An error occurred: #{e.message}"
end
```


## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle install`. To release a new version, update the version number in `version.rb`.

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/gklsan/simple_http_service.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SimpleHttpService project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the code of conduct.
