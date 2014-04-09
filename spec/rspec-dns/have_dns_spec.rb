require 'spec_helper'

def stub_records(strings)
  records = strings.map { |s| Dnsruby::RR.new_from_string(s) }
  resolver = Dnsruby::Resolver.new
  Dnsruby::Resolver.stub(:new) do
    yield if block_given?
    resolver
  end
  resolver.stub_chain(:query, :answer).and_return(records)
end

describe 'rspec-dns matchers' do

  describe '#have_dns' do
    context 'with a sigle record' do
      it 'can evalutate an A record' do
        stub_records(['example.com 86400 A 192.168.100.100'])

        'example.com'.should have_dns.with_type('A')
        'example.com'.should_not have_dns.with_type('TXT')
        'example.com'.should have_dns.with_type('A').and_address(Resolv::IPv4.create('192.168.100.100'))
      end

      it 'can evalutate a AAAA record' do
        stub_records(['example.com 86400 AAAA 2001:0002:6c::430'])

        'example.com'.should have_dns.with_type('AAAA')
        'example.com'.should_not have_dns.with_type('A')
        'example.com'.should have_dns.with_type('AAAA')
          .and_address(Resolv::IPv6.create('2001:0002:6c::430'))
      end

      it 'can evalutate a CNAME record' do
        stub_records(['www.example.com 300 IN CNAME example.com'])

        'example.com'.should have_dns.with_type('CNAME')
        'example.com'.should_not have_dns.with_type('AAAA')
        'example.com'.should have_dns.with_type('CNAME').and_name('www.example.com')
      end

      it 'can evalutate an MX record' do
        stub_records(['example.com. 7200 MX 40 mail.example.com.'])

        'example.com'.should have_dns.with_type('MX')
        'example.com'.should_not have_dns.with_type('CNAME')
        'example.com'.should have_dns.with_type('MX').and_preference(40)
        'example.com'.should have_dns.with_type('MX')
          .and_preference(40).and_exchange('mail.example.com')
        'example.com'.should_not have_dns.with_type('MX')
          .and_preference(30).and_exchange('mail.example.com')
        'example.com'.should_not have_dns.with_type('MX')
          .and_preference(40).and_exchange('example.com')
      end

      it 'can evalutate an NS record' do
        stub_records(['sub.example.com. 300 IN NS ns.sub.example.com.'])

        'example.com'.should have_dns.with_type('NS')
        'example.com'.should_not have_dns.with_type('MX')
        'example.com'.should have_dns.with_type('NS').and_domainname('ns.sub.example.com')
        'example.com'.should_not have_dns.with_type('NS').and_domainname('sub.example.com')
      end

      it 'can evalutate a PTR record' do
        stub_records(['ptrs.example.com. 300 IN PTR ptr.example.com.'])

        '192.168.100.100'.should have_dns.with_type('PTR')
        '192.168.100.100'.should_not have_dns.with_type('MX')
        '192.168.100.100'.should have_dns.with_type('PTR').and_domainname('ptr.example.com')
        '192.168.100.100'.should_not have_dns.with_type('PTR').and_domainname('ptrs.example.com')
      end

      it 'can evalutate an SOA record' do
        stub_records(['example.com 210 IN SOA ns.example.com a.example.com. 2014030712 60 25 3628800 900'])

        'example.com'.should have_dns.with_type('SOA')
        'example.com'.should_not have_dns.with_type('PTR')
        'example.com'.should have_dns.with_type('SOA')
          .and_mname('ns.example.com')
          .and_rname('a.example.com')
          .and_serial('2014030712')
          .and_refresh(60)
          .and_retry(25)
          .and_expire(3628800)
          .and_minimum(900)
        'example.com'.should_not have_dns.with_type('SOA')
          .and_mname('nstest.example.com')
      end

      it 'can evalutate a TXT record' do
        stub_records(['example.com. 300 IN TXT "v=spf1 a:example.com ~all"'])

        'example.com'.should have_dns.with_type('TXT')
        'example.com'.should_not have_dns.with_type('SOA')
        'example.com'.should have_dns.with_type('TXT').and_data('v=spf1 a:example.com ~all')
        'example.com'.should_not have_dns.with_type('TXT').and_data('v=spf2 a:example.com ~all')
      end
    end

    context 'with changable connection timeout' do
      it 'should timeout within 3 seconds in default' do
        stub_records(['example.com 86400 A 192.168.100.100']) do
          sleep 3
        end
        'example.com'.should_not have_dns.with_type('A')
      end

      it 'should not timeout within 3 seconds when timeout is 5' do
        RSpec.configuration.rspec_dns_connection_timeout = 5
        stub_records(['example.com 86400 A 192.168.100.100']) do
          sleep 3
        end
        'example.com'.should have_dns.with_type('A')
      end
    end
  end
end
