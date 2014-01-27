require 'erb'
require 'resolv'
require 'rspec/expectations'

require 'rspec-dns/have_dns'

RSpec.configure do |c|
  c.add_setting :rspec_dns_connection_timeout ,:default => 1
end
