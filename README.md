rspec-dns
=========
RSpec DNS is an rspec plugin for easy DNS testing. It uses the built-in Ruby 1.9 library Resolv and is customizable.

Installation
------------
If you're using bundler, add this line to your application's `Gemfile`:

```ruby
gem 'rspec-dns'
```

Don't forget to run the `bundle` command to install.

Or install it manually with:

    $ gem install rspec-dns

Usage
-----
RSpec DNS is best described by example. First, require `rspec-dns` in your `spec_helper.rb`:

```ruby
# spec/spec_helper.rb
require 'rspec'
require 'rspec-dns'
```

Then, create a spec like this:

```ruby
require 'spec_helper'

describe 'www.example.com' do
  it { should have_dns.with_type('TXT').and_ttl(300).and_data('a=b') }
end
```

Or group all your DNS tests into a single file or context:

```ruby
require 'spec_helper'

describe 'DNS tests' do
  'www.example.com'.should have_dns.with_type('TXT').and_ttl(300).and_data('a=b')
  'www.example.com'.should have_dns.with_type('A').and_ttl(300).and_value('1.2.3.4')
end
```

### Chain Methods
All of the method chains are actually [Resolv](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/resolv/rdoc/index.html) attributes on the record. You can prefix them with `and_`, `with_`, `and_with` or whatever your heart desires. The predicate is what is checked. The rest is syntactic sugar.

Depending on the type of record, the following attributes may be available:

- address
- bitmap
- cpu
- data
- emailbx
- exchange
- expire
- minimum
- mname
- name
- os
- port
- preference
- priority
- protocol
- refresh
- retry
- rmailbx
- rname
- serial
- target
- ttl
- type
- weight

If you try checking an attribute on a record that is non-existent (like checking the `rmailbx` on an `A` record), you'll get an error like this:

```text
Failure/Error: it { should have_dns.with_type('TXT').and_ftl(300).and_data('a=b') }
     NoMethodError:
       undefined method `rmailbx' for #<Resolv::DNS::Resource::IN::A:0x007fb56302ed90>
```

For this reason, you should always check the `type` attribute first in your chain.

Configuring
-----------
All configurations must be in your project root at `config/dns.yml`. This YAML file directly corresponds to the Resolv DNS initializer.

For example, to directly query your DNS servers (necessary for correct TTL tests), create a `config/dns.yml` file like this:

```yaml
nameserver:
  - 1.2.3.5
  - 6.7.8.9
```

The full list of configuration options can be found on the [Resolv docs](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/resolv/rdoc/index.html).

Contributing
------------
1. Fork the project on github
2. Create your feature branch
3. Open a Pull Request

License & Authors
-----------------
- Author: Seth Vargo (sethvargo@gmail.com)

```text
Copyright 2012-2013 Seth Vargo
Copyright 2012-2013 CustomInk, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
