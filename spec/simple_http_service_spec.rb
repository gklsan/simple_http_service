require 'net/http'
require 'rspec'
require 'json'
require 'simple_http_service'

RSpec.describe SimpleHttpService::Client do
  let(:url) { 'http://example.com' }
  let(:headers) { { accept: 'application/json', Authorization: 'Bearer token', content_type: 'application/json' } }
  let(:http_method) { :get }
  let(:open_timeout) { 10 }
  let(:read_timeout) { 10 }
  let(:write_timeout) { 10 }
  let(:write_timeout) { 10 }
  let(:retry_count) { 3 }
  let(:request_body) { { key: 'value' }.to_json }
  let(:opts) do
    {
      url: url,
      headers: headers,
      http_method: http_method,
      open_timeout: open_timeout,
      read_timeout: read_timeout,
      write_timeout: write_timeout,
      retry_count: retry_count,
      request_body: request_body
    }
  end

  subject { described_class.new(opts) }

  describe '#initialize' do
    context 'with valid options' do
      it 'initializes with the correct attributes' do
        expect(subject.uri).to eq(URI(url))
        expect(subject.headers).to eq(headers)
        expect(subject.http_method).to eq(http_method)
        expect(subject.read_timeout).to eq(read_timeout)
        expect(subject.write_timeout).to eq(write_timeout)
        expect(subject.retry_count).to eq(retry_count)
        expect(subject.request_body).to eq(request_body)
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

  describe '#set_headers' do
    it 'sets the correct headers' do
      request = Net::HTTP::Get.new(url)
      allow(subject).to receive(:request).and_return(request)

      subject.send(:set_headers)

      expect(request['Accept']).to eq(headers[:accept])
      expect(request['Authorization']).to eq(headers[:Authorization])
      expect(request['Content-Type']).to eq(headers[:content_type])
    end
  end

  describe '#enable_ssl' do
    let(:http) { subject.send(:http) }

    context 'when the uri scheme is https' do
      let(:url) { 'https://example.com' }

      it 'enables SSL and sets the SSL version' do
        subject.send(:enable_ssl)

        expect(http.use_ssl?).to be true
        expect(http.ssl_version).to eq(:TLSv1_2)
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
