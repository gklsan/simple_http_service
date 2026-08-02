module SimpleHttpService
  class Error < StandardError; end

  # Raised when a request would exceed the configured rate limit and
  # the client is not configured to wait for a free slot.
  class RateLimitExceeded < Error
    attr_reader :retry_after

    def initialize(msg, retry_after: nil)
      @retry_after = retry_after
      super(msg)
    end
  end

  # Sliding-window rate limiter, shared per key across all Client instances
  # in the process. Thread safe.
  class RateLimiter
    DEFAULT_LIMIT = 2
    DEFAULT_INTERVAL = 60

    attr_reader :limit, :interval

    class << self
      # Returns the limiter registered for +key+, creating it on first use.
      def for(key, limit: DEFAULT_LIMIT, interval: DEFAULT_INTERVAL)
        registry_mutex.synchronize do
          registry[key] ||= new(limit: limit, interval: interval)
        end
      end

      # Drops every registered limiter. Mainly useful in tests.
      def reset!
        registry_mutex.synchronize { registry.clear }
      end

      private

      def registry
        @registry ||= {}
      end

      def registry_mutex
        @registry_mutex ||= Mutex.new
      end
    end

    def initialize(limit: DEFAULT_LIMIT, interval: DEFAULT_INTERVAL)
      raise 'rate limit must be a positive integer' unless limit.to_i.positive?
      raise 'rate limit interval must be positive' unless interval.to_f.positive?

      @limit = limit.to_i
      @interval = interval.to_f
      @timestamps = []
      @mutex = Mutex.new
    end

    # Consumes one slot. Raises RateLimitExceeded when the window is full,
    # unless +wait+ is true, in which case it sleeps until a slot frees up.
    def acquire(wait: false)
      loop do
        retry_after = try_acquire
        return true unless retry_after

        unless wait
          raise RateLimitExceeded.new(
            "rate limit of #{limit} request(s) per #{interval.round} seconds exceeded, " \
            "retry in #{retry_after.ceil} second(s)",
            retry_after: retry_after
          )
        end

        sleep(retry_after)
      end
    end

    # Slots still available in the current window.
    def remaining
      @mutex.synchronize do
        prune
        limit - @timestamps.size
      end
    end

    private

    # Returns nil when a slot was taken, otherwise seconds until the next one.
    def try_acquire
      @mutex.synchronize do
        prune
        if @timestamps.size < limit
          @timestamps << now
          return nil
        end

        [@timestamps.first + interval - now, 0.001].max
      end
    end

    def prune
      cutoff = now - interval
      @timestamps.shift while @timestamps.first && @timestamps.first <= cutoff
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end