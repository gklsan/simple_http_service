require 'net/http'
require 'rspec'
require 'json'
require 'simple_http_service'

RSpec.describe SimpleHttpService::Client do
  let(:url) { 'http://example.com' }
  let(:headers) { { accept: 'application/json', authorization: 'Bearer token', content_type: 'application/json' } }
  let(:http_method) { :get }
  let(:open_timeout) { 10 }
  let(:read_timeout) { 10 }
  let(:write_timeout) { 10 }
  let(:write_timeout) { 10 }
  let(:additional_headers) { {} }
  let(:request_body) { { key: 'value' }.to_json }
  let(:opts) do
    {
      url: url,
      headers: headers,
      http_method: http_method,
      open_timeout: open_timeout,
      read_timeout: read_timeout,
      write_timeout: write_timeout,
      request_body: request_body,
      additional_headers: additional_headers
    }
  end

  subject { described_class.new(opts) }

  before { SimpleHttpService::RateLimiter.reset! }

  describe '#initialize' do
    context 'with valid options' do
      it 'initializes with the correct attributes' do
        expect(subject.uri).to eq(URI(url))
        expect(subject.headers).to eq(headers)
        expect(subject.http_method).to eq(http_method)
        expect(subject.read_timeout).to eq(read_timeout)
        expect(subject.write_timeout).to eq(write_timeout)
        expect(subject.request_body).to eq(request_body)
        expect(subject.additional_headers).to eq(additional_headers)
      end
    end

    context 'without url' do
      it 'raises an error' do
        expect { described_class.new(opts.except(:url)) }.to raise_error('URL must be present')
      end
    end

    context 'without http_method' do
      it 'raises an error' do
        expect { described_class.new(opts.except(:http_method)) }.to raise_error('http_method must be present')
      end
    end
  end

  describe '#call' do
    it 'makes an HTTP request' do
      allow(subject).to receive(:enable_ssl)
      allow(subject).to receive(:set_headers)
      allow(subject).to receive(:set_timeout)
      allow(subject).to receive(:http).and_return(double(request: true))

      expect(subject.call).to be true
    end
  end

  describe 'rate limiting' do
    let(:stubbed_http) { double(request: true) }

    before do
      allow(subject).to receive(:enable_ssl)
      allow(subject).to receive(:set_headers)
      allow(subject).to receive(:set_timeout)
      allow(subject).to receive(:http).and_return(stubbed_http)
    end

    it 'is disabled unless a rate_limit is passed' do
      expect(subject.rate_limit).to eq({})
      expect(subject.rate_limiter).to be_nil
      expect { 10.times { subject.call } }.not_to raise_error
    end

    context 'with a rate_limit of 2 per minute' do
      let(:opts) { super().merge(rate_limit: { limit: 2, interval: 60 }) }

      it 'allows requests up to the limit' do
        expect { 2.times { subject.call } }.not_to raise_error
      end

      it 'raises once the limit is exceeded' do
        2.times { subject.call }

        expect { subject.call }.to raise_error(SimpleHttpService::RateLimitExceeded)
      end

      it 'shares the window across clients hitting the same host' do
        other = described_class.new(opts)
        allow(other).to receive(:enable_ssl)
        allow(other).to receive(:set_headers)
        allow(other).to receive(:set_timeout)
        allow(other).to receive(:http).and_return(stubbed_http)

        2.times { subject.call }

        expect { other.call }.to raise_error(SimpleHttpService::RateLimitExceeded)
      end
    end

    context 'with only a limit given' do
      let(:opts) { super().merge(rate_limit: { limit: 5 }) }

      it 'defaults the interval to 60 seconds' do
        expect(subject.rate_limiter.interval).to eq(60)
        expect(subject.rate_limiter.limit).to eq(5)
      end
    end

    context 'with a custom key' do
      let(:opts) { super().merge(rate_limit: { limit: 1, key: 'my-bucket' }) }

      it 'buckets by that key instead of the host' do
        other = described_class.new(opts.merge(url: 'http://other.example.com'))
        allow(other).to receive(:enable_ssl)
        allow(other).to receive(:set_headers)
        allow(other).to receive(:set_timeout)
        allow(other).to receive(:http).and_return(stubbed_http)

        subject.call

        expect { other.call }.to raise_error(SimpleHttpService::RateLimitExceeded)
      end
    end
  end

  describe '#set_headers' do
    it 'sets the correct headers' do
      request = Net::HTTP::Get.new(url)
      allow(subject).to receive(:request).and_return(request)

      subject.send(:set_headers)

      expect(request['Accept']).to eq(headers[:accept])
      expect(request['Authorization']).to eq(headers[:authorization])
      expect(request['Content-Type']).to eq(headers[:content_type])
      expect(request['Cookie']).to eq(headers[:cookie])
    end

    context 'with additional headers' do
      let(:additional_headers) { { 'Custom-Header' => 'value' } }

      it 'sets additional headers' do
        request = Net::HTTP::Get.new(url)
        allow(subject).to receive(:request).and_return(request)

        subject.send(:set_headers)
        expect(request['Custom-Header']).to eq('value')
      end
    end
  end

  describe '#enable_ssl' do
    let(:http) { subject.send(:http) }

    context 'when the uri scheme is https' do
      let(:url) { 'https://example.com' }

      it 'enables SSL' do
        subject.send(:enable_ssl)

        expect(http.use_ssl?).to be true
      end
    end

    context 'when the uri scheme is not https' do
      it 'does not enable SSL' do
        subject.send(:enable_ssl)

        expect(http.use_ssl?).to be false
        expect(http.ssl_version).to be_nil
      end
    end
  end

  describe '#set_timeout' do
    let(:http) { subject.send(:http) }

    it 'sets the correct timeouts' do
      expect(http).to receive(:open_timeout=).with(open_timeout).exactly(:once)
      expect(http).to receive(:read_timeout=).with(read_timeout).exactly(:once)
      expect(http).to receive(:write_timeout=).with(write_timeout).exactly(:once)

      subject.send(:set_timeout)
    end
  end
end
