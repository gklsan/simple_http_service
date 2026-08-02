require 'rspec'
require 'simple_http_service'

RSpec.describe SimpleHttpService::RateLimiter do
  before { described_class.reset! }

  describe '#acquire' do
    subject { described_class.new(limit: 2, interval: 60) }

    it 'allows requests up to the limit' do
      expect(subject.acquire).to be true
      expect(subject.acquire).to be true
      expect(subject.remaining).to eq(0)
    end

    it 'raises once the limit is exceeded' do
      2.times { subject.acquire }

      expect { subject.acquire }.to raise_error(SimpleHttpService::RateLimitExceeded, /2 request\(s\) per 60 seconds/)
    end

    it 'exposes retry_after on the raised error' do
      2.times { subject.acquire }

      subject.acquire
    rescue SimpleHttpService::RateLimitExceeded => e
      expect(e.retry_after).to be > 0
      expect(e.retry_after).to be <= 60
    end

    it 'frees slots once the window slides past' do
      limiter = described_class.new(limit: 2, interval: 0.05)
      2.times { limiter.acquire }

      sleep 0.06

      expect(limiter.acquire).to be true
    end

    context 'with wait enabled' do
      it 'blocks until a slot is free instead of raising' do
        limiter = described_class.new(limit: 1, interval: 0.05)
        limiter.acquire

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        expect(limiter.acquire(wait: true)).to be true
        expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be >= 0.04
      end
    end
  end

  describe '#initialize' do
    it 'requires a limit' do
      expect { described_class.new }.to raise_error(ArgumentError, /limit/)
    end

    it 'rejects a non positive limit' do
      expect { described_class.new(limit: 0) }.to raise_error('rate limit must be a positive integer')
    end

    it 'rejects a non positive interval' do
      expect { described_class.new(limit: 2, interval: 0) }.to raise_error('rate limit interval must be positive')
    end

    it 'defaults the interval to 60 seconds' do
      expect(described_class.new(limit: 2).interval).to eq(60)
    end
  end

  describe '.for' do
    it 'shares one limiter per key' do
      expect(described_class.for('a', limit: 2)).to equal(described_class.for('a', limit: 2))
      expect(described_class.for('a', limit: 2)).not_to equal(described_class.for('b', limit: 2))
    end
  end
end