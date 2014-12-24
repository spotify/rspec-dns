require 'spec_helper'

def stub_records(strings)
  records = strings.map { |s| Dnsruby::RR.new_from_string(s) }
  resolver = Dnsruby::Resolver.new
  allow(Dnsruby::Resolver).to receive(:new) do
    yield if block_given?
    resolver
  end
  allow(resolver).to receive_message_chain(:query, :answer).and_return(records)
end

describe 'rspec-dns matchers' do

  describe '#have_dns' do
    context 'with a sigle record' do
      it 'can evalutate an A record' do
        stub_records(['example.com 86400 A 192.0.2.4'])

        expect('example.com').to have_dns.with_type('A')
        expect('example.com').to_not have_dns.with_type('TXT')
        expect('example.com').to have_dns.with_type('A').and_address('192.0.2.4')
      end

      it 'can evalutate a AAAA record' do
        stub_records(['example.com 86400 AAAA 2001:DB8:6c::430'])

        expect('example.com').to have_dns.with_type('AAAA')
        expect('example.com').to_not have_dns.with_type('A')
        expect('example.com').to have_dns.with_type('AAAA')
          .and_address('2001:DB8:6C::430')
      end

      it 'can evalutate an A/AAAA record with IPAddr range' do
        stub_records(['example.com 86400 A 192.0.2.4',
                      'example.com 86400 AAAA 2001:DB8:6c::430'])

        expect('example.com').to have_dns.with_type('A')
          .and_address('192.0.2.0/24')
        expect('example.com').to have_dns.with_type('AAAA')
          .and_address('2001:DB8:6C::/64')
      end

      it 'can evalutate a CNAME record' do
        stub_records(['www.example.com 300 IN CNAME example.com'])

        expect('example.com').to have_dns.with_type('CNAME')
        expect('example.com').to_not have_dns.with_type('AAAA')
        expect('example.com').to have_dns.with_type('CNAME').and_name('www.example.com')
      end

      it 'can evalutate an MX record' do
        stub_records(['example.com. 7200 MX 40 mail.example.com.'])

        expect('example.com').to have_dns.with_type('MX')
        expect('example.com').to_not have_dns.with_type('CNAME')
        expect('example.com').to have_dns.with_type('MX').and_preference(40)
        expect('example.com').to have_dns.with_type('MX')
          .and_preference(40).and_exchange('mail.example.com')
        expect('example.com').to_not have_dns.with_type('MX')
          .and_preference(30).and_exchange('mail.example.com')
        expect('example.com').to_not have_dns.with_type('MX')
          .and_preference(40).and_exchange('example.com')
      end

      it 'can evalutate an NS record' do
        stub_records(['sub.example.com. 300 IN NS ns.sub.example.com.'])

        expect('example.com').to have_dns.with_type('NS')
        expect('example.com').to_not have_dns.with_type('MX')
        expect('example.com').to have_dns.with_type('NS').and_domainname('ns.sub.example.com')
        expect('example.com').to_not have_dns.with_type('NS').and_domainname('sub.example.com')
      end

      it 'can evalutate a PTR record' do
        stub_records(['ptrs.example.com. 300 IN PTR ptr.example.com.'])

        expect('192.168.100.100').to have_dns.with_type('PTR')
        expect('192.168.100.100').to_not have_dns.with_type('MX')
        expect('192.168.100.100').to have_dns.with_type('PTR').and_domainname('ptr.example.com')
        expect('192.168.100.100').to_not have_dns.with_type('PTR').and_domainname('ptrs.example.com')
      end

      it 'can evalutate an SOA record' do
        stub_records(['example.com 210 IN SOA ns.example.com a.example.com. 2014030712 60 25 3628800 900'])

        expect('example.com').to have_dns.with_type('SOA')
        expect('example.com').to_not have_dns.with_type('PTR')
        expect('example.com').to have_dns.with_type('SOA')
          .and_mname('ns.example.com')
          .and_rname('a.example.com')
          .and_serial('2014030712')
          .and_refresh(60)
          .and_retry(25)
          .and_expire(3628800)
          .and_minimum(900)
        expect('example.com').to_not have_dns.with_type('SOA')
          .and_mname('nstest.example.com')
      end

      it 'can evalutate a TXT record' do
        stub_records(['example.com. 300 IN TXT "v=spf1 a:example.com ~all"'])

        expect('example.com').to have_dns.with_type('TXT')
        expect('example.com').to_not have_dns.with_type('SOA')
        expect('example.com').to have_dns.with_type('TXT').and_data('v=spf1 a:example.com ~all')
        expect('example.com').to_not have_dns.with_type('TXT').and_data('v=spf2 a:example.com ~all')
      end
    end

    context 'with config chain' do
      it 'should accept config chain' do
        stub_records(['example.com 86400 A 192.0.2.1'])
        expect('example.com').to have_dns.with_type('A')
          .config(nameserver: '192.0.2.4')
      end
    end

    context 'with zone file' do
      it 'can evalutate an A record from zone file with origin' do
        file = 'spec/rspec-dns/example.zone'
        origin =  'example.com.'

        expect('example.com').to have_dns.with_type('NS')
          .and_domainname('ns.example.com')
          .in_zone_file(file, origin)
        expect('example.com').to have_dns.with_type('A')
          .and_address('192.0.2.4')
          .in_zone_file(file, origin)
        expect('example.com').to have_dns.with_type('MX')
          .and_preference(40).and_exchange('mail.example.com')
          .in_zone_file(file, origin)
        expect('www.example.com').to have_dns.with_type('A')
          .and_address('192.0.2.4')
          .in_zone_file(file, origin)
        expect('www.example.com').to have_dns.with_type('AAAA')
          .and_address('2001:DB8:6C::430')
          .in_zone_file(file, origin)
      end
      it 'can evalutate an A record from zone file without origin' do
        file = 'spec/rspec-dns/example.zone'

        expect('.').to have_dns.with_type('NS')
          .and_domainname('ns').in_zone_file(file)
        expect('www').to have_dns.with_type('A')
          .and_address('192.0.2.4').in_zone_file(file)
      end
      it 'can evalutate an A record with dns servers if file is nil' do
        file = nil
        stub_records(['example.com 86400 A 192.0.2.4'])
        expect('example.com').to have_dns.with_type('A')
          .and_address('192.0.2.4')
          .in_zone_file(file)
        expect('example.com').to have_dns.with_type('A')
          .and_address('192.0.2.4')
          .in_zone_file
      end
    end

    context 'with changable connection timeout' do
      it 'is_expected.to timeout within 3 seconds in default' do
        stub_records(['example.com 86400 A 192.168.100.100']) do
          sleep 3
        end
        expect('example.com').to_not have_dns.with_type('A')
      end

      it 'is_expected.to not timeout within 3 seconds when timeout is 5' do
        RSpec.configuration.rspec_dns_connection_timeout = 5
        stub_records(['example.com 86400 A 192.168.100.100']) do
          sleep 3
        end
        expect('example.com').to have_dns.with_type('A')
      end
    end
  end
end
