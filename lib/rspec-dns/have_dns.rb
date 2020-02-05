RSpec.configure do |c|
  c.add_setting :rspec_dns_connection_timeout, :default => 1
end

RSpec::Matchers.define :have_dns do
  match do |dns|
    @dns = dns
    @exceptions = []

    @records = []
    @records.concat(_records.authority) if @authority
    @records.concat(_records.additional) if @additional
    @records.concat(_records.answer) if @answer || (!@authority && !@additional)

    results = @records.find_all do |record|
      matched = _options.all? do |option, value|
        begin
          # To distinguish types because not all Resolv returns have type
          if ipaddr = (IPAddr.new(value) rescue nil) # IPAddr(v4/v6)?
            ipaddr.include?(record.send(option).to_s)
          elsif value.is_a? String
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

  failure_message do |actual|
    if !@exceptions.empty?
      "tried to look up #{actual} but got #{@exceptions.size} exception(s): #{@exceptions.join(", ")}"
    elsif @refuse_request
      "expected #{actual} to have request refused"
    elsif @at_least
      "expected #{actual} to have: #{@at_least} records of #{_pretty_print_options}, but found #{@number_matched}. Other records were: #{_pretty_print_records}"
    else
      "expected #{actual} to have: #{_pretty_print_options}, but did not. other records were: #{_pretty_print_records}"
    end
  end

  failure_message_when_negated do |actual|
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
    @answer = @additional = false
  end

  chain :in_additional do
    @additional = true
    @authority = @answer = false
  end

  chain :in_answer do
    @answer = true
    @authority = @additional = false
  end

  chain :in_authority_or_answer do
    @authority = @answer = true
    @additional = false
  end

  chain :at_least do |actual|
    @at_least = actual
  end

  chain :refuse_request do
    @refuse_request = true
  end

  chain :config do |c|
    @config = c
  end

  chain :in_zone_file do |file = nil, origin = '.'|
    @zone_file = file
    @zone_origin = origin
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
      _symbolize_keys(YAML::load(ERB.new(File.read(_config_file) ).result))
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
    @_name ||= if (IPAddr.new(@dns) rescue nil) # Check if IPAddr(v4,v6)
                 IPAddr.new(@dns).reverse
               else
                 @dns
               end

    if @zone_file
      @_records = Dnsruby::Message.new
      rrs = Dnsruby::ZoneReader.new(@zone_origin).process_file(@zone_file)
      rrs.each { |rr| @_records.add_answer(rr) if @_name == rr.name.to_s  }
    end

    @_records ||= begin
      config = _config || {}
      # Backwards compatible config option for rspec-dnsruby
      query_timeout = config[:timeouts] || RSpec.configuration.rspec_dns_connection_timeout
      Timeout::timeout(query_timeout + 0.2) do
        resolver =  Dnsruby::Resolver.new(config)
        resolver.query_timeout = query_timeout
        resolver.do_caching = false
        resolver.query(@_name, _options[:type] || Dnsruby::Types.ANY)
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
    "\n  (#{_options.sort.map { |k, v| "#{k}:#{v.inspect}" }.join(', ')})\n"
  end

  def _pretty_print_records
    "\n" + @records.map { |r| r.to_s }.join("\n")
  end

end
