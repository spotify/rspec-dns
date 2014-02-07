require 'dnsruby'

RSpec::Matchers.define :have_dns do
  match do |dns|
    @dns = dns
    @exceptions = []

    if @authority
      @records = _records.authority
    else
      @records = _records.answer
    end

    results = @records.find_all do |record|
      matched = _options.all? do |option, value|
        begin
          # To distinguish types because not all Resolv returns have type
          if value.is_a? String
            record.send(option).to_s == value
          elsif value.is_a? Regexp
            record.send(option).to_s =~ value
          else
            record.send(option) == value
          end
        rescue Exception => e
          @exceptions << e.message
          false
        end
      end
      matched
    end

    @number_matched = results.count

    fail_with('exceptions') if !@exceptions.empty?
    if @refuse_request
      @refuse_request_received
    else
      @number_matched >= (@at_least ? @at_least : 1)
    end
  end

  failure_message_for_should do |actual|
    if !@exceptions.empty?
      "got #{@exceptions.size} exception(s):\n#{@exceptions.join("\n")}"
    elsif @refuse_request
      "expected #{actual} to have request refused"
    elsif @at_least
      "expected #{actual} to have: #{@at_least} records of #{_pretty_print_options}, but found #{@number_matched}. Other records were: #{_pretty_print_records}"
    else
      "expected #{actual} to have: #{_pretty_print_options}, but did not. other records were: #{_pretty_print_records}"
    end
  end

  failure_message_for_should_not do |actual|
    if !@exceptions.empty?
      "got #{@exceptions.size} exception(s):\n#{@exceptions.join("\n")}"
    elsif @refuse_request
      "expected #{actual} not to be refused"
    else
      "expected #{actual} not to have #{_pretty_print_options}, but it did. the records were: #{_pretty_print_records}"
    end
  end

  def description
    "have the correct dns entries with #{_options}"
  end

  chain :in_authority do
    @authority = true
  end

  chain :at_least do |actual|
    @at_least = actual
  end

  chain :refuse_request do
    @refuse_request = true
  end

  def method_missing(m, *args, &block)
    if m.to_s =~ /(and\_with|and|with)?\_(.*)$/
      _options[$2.to_sym] = args.first
      self
    else
      super
    end
  end

  def _config
    @config ||= if File.exists?(_config_file)
      require 'yaml'
      config = _symbolize_keys(YAML::load(ERB.new(File.read(_config_file) ).result))
    else
      nil
    end
  end

  def _config_file
    File.join('config', 'dns.yml')
  end

  def _symbolize_keys(hash)
    hash.inject({}){|result, (key, value)|
      new_key = case key
                when String then key.to_sym
                else key
                end
      new_value = case value
                  when Hash then _symbolize_keys(value)
                  else value
                  end
      result[new_key] = new_value
      result
    }
  end

  def _options
    @_options ||= {}
  end

  def _records
    @_records ||= begin
      Timeout::timeout(10) do
        config = _config || {}
        resolver =  Dnsruby::Resolver.new(config)
        # Backwards compatible config option from the version which uses ruby stdlib
        resolver.query_timeout = config[:timeouts] if config[:timeouts]
        resolver.query(@dns, Dnsruby::Types.ANY)
      end
    rescue Exception => e
      if Dnsruby::NXDomain === e
        @exceptions << "Have not received any records"
      elsif Dnsruby::Refused === e && @refuse_request
        @refuse_request_received = true
      else
        @exceptions << e.message
      end
      Dnsruby::Message.new
    end
  end

  def _pretty_print_options
    "\n  (#{_options.sort.collect{ |k,v| "#{k}:#{v.inspect}" }.join(', ')})\n"
  end

  def _pretty_print_records
    "\n" + @records.collect{ |r| r.to_s }.join("\n")
  end

end
