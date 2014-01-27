require 'spec_helper'
require_relative '../../lib/rspec-dns/have_dns'

describe 'rspec-dns matchers' do

  describe '#have_dns' do
    context 'with a sigle record' do
      it 'can evalutate an A record' do
        records = [Resolv::DNS::Resource::IN::A.new('192.168.100.100')]
        Resolv::DNS.stub_chain(:new, :getresources).and_return(records)

        'example.com'.should have_dns.with_type('A')
        'example.com'.should_not have_dns.with_type('TXT')
        'example.com'.should have_dns.with_type('A').and_address(Resolv::IPv4.create('192.168.100.100'))
      end

      it 'can evalutate a AAAA record' do
        records = [Resolv::DNS::Resource::IN::AAAA.new('2001:0002:6c::430')]
        Resolv::DNS.stub_chain(:new, :getresources).and_return(records)

        'example.com'.should have_dns.with_type('AAAA')
        'example.com'.should_not have_dns.with_type('A')
        'example.com'.should have_dns.with_type('AAAA')
          .and_address(Resolv::IPv6.create('2001:0002:6c::430'))
      end

      it 'can evalutate a CNAME record' do
        records = [Resolv::DNS::Resource::IN::CNAME.new('www.example.com')]
        Resolv::DNS.stub_chain(:new, :getresources).and_return(records)

        'example.com'.should have_dns.with_type('CNAME')
        'example.com'.should_not have_dns.with_type('AAAA')
        'example.com'.should have_dns.with_type('CNAME').and_name('www.example.com')
      end

      it 'can evalutate an MX record' do
        records = [Resolv::DNS::Resource::IN::MX.new(40, 'mail.example.com')]
        Resolv::DNS.stub_chain(:new, :getresources).and_return(records)

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

      it 'can evalutate a CNAME record' do
        records = [Resolv::DNS::Resource::IN::NS.new('ns.sub.example.com')]
        Resolv::DNS.stub_chain(:new, :getresources).and_return(records)

        'example.com'.should have_dns.with_type('NS')
        'example.com'.should_not have_dns.with_type('MX')
        'example.com'.should have_dns.with_type('NS').and_name('ns.sub.example.com')
        'example.com'.should_not have_dns.with_type('NS').and_name('sub.example.com')
      end

      it 'can evalutate a PTR record' do
        records = [Resolv::DNS::Resource::IN::PTR.new('mail2.example.org')]
        Resolv::DNS.stub_chain(:new, :getresources).and_return(records)

        '192.168.100.100'.should have_dns.with_type('PTR')
        '192.168.100.100'.should_not have_dns.with_type('MX')
        '192.168.100.100'.should have_dns.with_type('PTR').and_name('mail2.example.org')
        '192.168.100.100'.should_not have_dns.with_type('PTR').and_name('mail1.example.org')
      end

      it 'can evalutate an SOA record' do
        records = [Resolv::DNS::Resource::IN::SOA.new('ns.sub.example.com',
                                                      'admin.sub.example.com',
                                                      '2014012701',
                                                      7200,
                                                      1800,
                                                      1209600,
                                                      300)]

        Resolv::DNS.stub_chain(:new, :getresources).and_return(records)

        'example.com'.should have_dns.with_type('SOA')
        'example.com'.should_not have_dns.with_type('PTR')
        'example.com'.should have_dns.with_type('SOA')
          .and_mname('ns.sub.example.com')
          .and_rname('admin.sub.example.com')
          .and_serial('2014012701')
          .and_refresh(7200)
          .and_retry(1800)
          .and_expire(1209600)
          .and_minimum(300)
        'example.com'.should_not have_dns.with_type('SOA')
          .and_mname('ns.sub.example.com')
          .and_rname('admin.sub.example.com')
          .and_serial('2014012601')
          .and_refresh(7200)
          .and_retry(1800)
          .and_expire(1209600)
          .and_minimum(300)
      end

      it 'can evalutate a CNAME record' do
        records = [Resolv::DNS::Resource::IN::TXT.new('v=spf1 a:example.com ~all')]
        Resolv::DNS.stub_chain(:new, :getresources).and_return(records)

        'example.com'.should have_dns.with_type('TXT')
        'example.com'.should_not have_dns.with_type('SOA')
        'example.com'.should have_dns.with_type('TXT').and_data('v=spf1 a:example.com ~all')
        'example.com'.should_not have_dns.with_type('TXT').and_data('v=spf2 a:example.com ~all')
      end
    end

    context 'with multiple records' do
    end

    context 'with changable connection timeout' do
      it 'should timeout within 2 seconds in default' do
        records = [Resolv::DNS::Resource::IN::A.new('192.168.100.100')]
        Resolv::DNS.stub_chain(:new, :getresources) { sleep 2 ; records }

        $stderr.should_receive(:puts).with("Connection timed out for example.com")
        'example.com'.should_not have_dns.with_type('A')
      end

      it 'should not timeout within 2 seconds when timeout is 5' do
        records = [Resolv::DNS::Resource::IN::A.new('192.168.100.100')]
        Resolv::DNS.stub_chain(:new, :getresources) { sleep 2 ; records }

        RSpec.configuration.rspec_dns_connection_timeout = 5

        $stderr.should_not_receive(:puts).with("Connection timed out for example.com")
        'example.com'.should have_dns.with_type('A')
      end
    end
  end
end
