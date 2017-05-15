   Oh Most Grandiose and Puissant Emacs, please be in -*- org -*- mode!

#+STARTUP: showeverything

I'm using 'bundle install --path vendor/bundle'.

* Made various changes in Gemfile; see diff.

        diff --git Gemfile Gemfile
        index 346487e..86ae041 100755
        --- Gemfile
        +++ Gemfile
        @@ -7,11 +7,12 @@ DM_VERSION = '~> 1.2.0'
         
         gem 'rake', '~> 0.9.2'
         gem 'request_store', '~> 1.0.5'
        -gem 'thin', '~> 1.3.1'
        +# gem 'thin', '~> 1.3.1'
        +gem 'thin', '~> 1.7.0'
         
         gem 'rails',                       RAILS_VERSION
         gem 'jquery-rails'
        -gem 'bundler',                     '~> 1.6.1'
        +gem 'bundler',                     '> 1.6.1'
         
         # DateTime Patches
         gem 'home_run',                    :require => 'date', :platforms => :mri
        @@ -50,7 +51,8 @@ gem 'jammit',                      '~> 0.5.4'
         gem 'devise',                      '~> 1.5.4'
         gem 'dm-devise',                   '~> 1.5'
         gem 'rubycas-client'
        -gem 'devise_cas_authenticatable',  :git => 'http://github.com/Snorby/snorby_cas_authenticatable.git'
        +# gem 'devise_cas_authenticatable',  :git => 'http://github.com/Snorby/snorby_cas_authenticatable.git'
        +gem 'devise_cas_authenticatable'
         gem 'devise_ldap_authenticatable', '~> 0.5.1'
         gem "mail",                        '~> 2.3'
         gem "RedCloth",                    "~> 4.2.9", :require => 'redcloth'
        @@ -60,7 +62,9 @@ gem 'ezprint',                     :git => 'http://github.com/mephux/ezprint.git
         gem 'daemons',                     '~> 1.1.0'
         gem 'delayed_job',                 '~> 3.0.1'
         gem 'delayed_job_data_mapper',     '~> 1.0.0.rc', :git => 'https://github.com/Snorby/delayed_job_data_mapper.git'
        -gem 'rmagick',                     '~> 2.13.1'
        +# gem 'delayed_job_data_mapper', '1.0.0'
        +# gem 'rmagick',                     '~> 2.13.1'
        +gem 'rmagick',                     '~> 2.16.0'
         gem 'dm-noisy-failures'
         
         gem 'dm-paperclip',                '~> 2.4.1', :git => 'http://github.com/Snorby/dm-paperclip.git'
        @@ -74,7 +78,8 @@ gem 'snmp',                        '~> 1.1.0'
         gem 'getopt',                      '~> 1.4.1'
         gem 'net-ssh',                     '2.9.1'
         gem 'net-scp',                     '1.0.4'
        -gem 'json',                        '1.6.1'
        +# gem 'json',                        '1.6.1'
        +gem 'json',                        '1.6.1', :path => 'foo/json-1.6.1'
         gem 'chef',                        '11.12.8'
         gem 'moneta',                        '0.6.0'
         gem 'cancan',                      '~> 1.6.7'

* Handle the json-1.6.1 problem

    - Tried making this patch, as per https://github.com/flori/json/issues/229#issuecomment-68822948:

             $ pushd vendor/bundle/ruby/2.3.0/gems/json-1.6.1/ext/json/ext/generator/
             $ diff -u generator.c.orig generator.c
             --- generator.c.orig	2017-05-13 19:37:23.480681077 -0500
             +++ generator.c	2017-05-13 19:37:37.124301690 -0500
             @@ -402,7 +402,7 @@
              
                  if (len > 0) {
                      result = fbuffer_alloc_with_length(len);
             -        fbuffer_append(result, FBUFFER_PAIR(fb));
             +        fbuffer_append(result, FBUFFER_PTR(fb), FBUFFER_LEN(fb));
                  } else {
                      result = fbuffer_alloc();
                  }
             @@ -949,7 +949,7 @@
              
              static VALUE fbuffer_to_s(FBuffer *fb)
              {
             -    VALUE result = rb_str_new(FBUFFER_PAIR(fb));
             +    VALUE result = rb_str_new(FBUFFER_PTR(fb), FBUFFER_LEN(fb));
                  fbuffer_free(fb);
                  FORCE_UTF8(result);
                  return result;
     
       But that doesn't work, because each time I do
     
             $ bundle install --path vendor/bundle
     
       it refetches the source and blows away my patch.  So, next step was:

    - In Gemfile, tried upgrading json from 1.6.1 to 1.8.2

      According to commit history of https://github.com/flori/json,
      commit 18b300009 and later commit 4dd360f7 fixed the FBUFFER_PAIR()
      problem in basically the same way as my attempted patch.  1.8.2 is
      the first release that has that fix, and is thus closest to 1.6.1.
      See https://rubygems.org/gems/json/versions for release history.
     
      But nope, that fails too.

    - Tried this in Gemfile:

            -gem 'json',                        '1.6.1'
            +gem 'json',                        '1.6.1', :path => 'vendor/bundle/ruby/2.3.0/gems/json-1.6.1'

    - Finally took jaegerca's advice in IRC

            $ mkdir foo
            $ cd foo
            $ gem unpack -v 1.6.1 json
            $ emacs Gemfile
              -gem 'json',                        '1.6.1'
              +gem 'json',                        '1.6.1', :path => 'foo/json-1.6.1'
            $ cd ..
            ( adjust patch from previous step to
              apply to foo/json-1.6.1/.../generator.c)
            $ patch -p0 < ots-json-1.6.1-patch.txt

* Next, upgrade 'thin', to avoid eventmachine error

    - Got this error about eventmachine

      https://hastebin.com/atavukakon.txt
     
            $ bundle install --path vendor/bundle
            Fetching gem metadata from http://rubygems.org/............
            Fetching version metadata from http://rubygems.org/...
            Fetching dependency metadata from http://rubygems.org/..
            Resolving dependencies...
            Using rake 0.9.6
            Using Platform 0.4.0
            Using open4 1.3.0
            Using RedCloth 4.2.9
            Using multi_json 1.6.0
            Using builder 3.0.4
            Using i18n 0.6.1
            Using erubis 2.7.0
            Using rack 1.3.10
            Using hike 1.2.1
            Using tilt 1.3.3
            Using mime-types 1.21
            Using polyglot 0.3.3
            Using arel 2.2.3
            Using tzinfo 0.3.35
            Using addressable 2.2.8
            Using ansi 1.4.3
            Using bcrypt-ruby 3.0.1
            Using bundler 1.13.6
            Using cancan 1.6.9
            Using highline 1.6.15
            Using net-ssh 2.9.1
            Using nokogiri 1.5.6
            Using ffi 1.3.1
            Using rubyzip 0.9.9
            Using websocket 1.0.7
            Using hashie 2.1.2
            Using json 1.6.1 from source at `vendor/bundle/ruby/2.3.0/gems/json-1.6.1`
            Using mixlib-log 1.6.0
            Using diff-lcs 1.2.4
            Using mixlib-cli 1.5.0
            Using mixlib-config 2.2.1
            Using mixlib-shellout 1.6.1
            Using ipaddress 0.8.0
            Using systemu 2.5.2
            Using yajl-ruby 1.2.1
            Using coderay 1.1.0
            Using method_source 0.8.2
            Using slop 3.6.0
            Using chronic 0.3.0
            Using closure-compiler 1.1.8
            Using daemons 1.1.9
            Using fastercsv 1.5.5
            Using json_pure 1.8.6 (was 1.7.7)
            Using stringex 1.5.1
            Using uuidtools 2.1.3
            Using orm_adapter 0.0.7
            Using net-ldap 0.2.2
            Using thor 0.14.6
            Using dm-paperclip 2.4.1 from http://github.com/Snorby/dm-paperclip.git (at master@f3101cc)
            Using ruby-graphviz 1.0.8
            Installing eventmachine 1.0.0 with native extensions
            Using pdfkit 0.4.6
            Using geoip 1.1.2
            Using getopt 1.4.1
            Using gmaps4rails 1.5.6
            Using home_run 1.0.7
            Using minitest 4.6.0
            Using moneta 0.6.0
            Using net-dns 0.6.1
            Using netaddr 1.5.0
            Using request_store 1.0.5
            Installing rmagick 2.13.2 with native extensions
            Using rspec-core 2.0.1
            Using simple_form 1.2.2
            Using snmp 1.1.0
            Using whois 2.7.0
            Using will_paginate 3.0.4
            Using POpen4 0.1.4
            Using activesupport 3.1.11
            Using rack-cache 1.2
            Using rack-mount 0.8.3
            Using rack-test 0.6.2
            Using warden 1.2.1
            Using rack-ssl 1.3.3
            Using puma 1.6.3
            Using sprockets 2.0.4
            Using rest-client 1.6.9
            Using treetop 1.4.12
            Using dm-core 1.2.0
            Using data_objects 0.10.12
            Using turn 0.9.6
            Using net-scp 1.0.4
            Using net-sftp 2.0.5
            Using net-ssh-gateway 1.1.0
            Using xpath 1.0.0
            Using childprocess 0.3.8
            Using rdoc 3.12.1
            Using chef-zero 2.0.2
            Using mixlib-authentication 1.3.0
            Using rspec-expectations 2.0.1
            Using ohai 7.0.4
            Using pry 0.10.3
            Gem::Ext::BuildError: ERROR: Failed to build gem native extension.
            
            current directory:
            /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/eventmachine-1.0.0/ext
            /usr/bin/ruby2.3 -r ./siteconf20170513-14901-8xyd7w.rb extconf.rb
            checking for rb_trap_immediate in ruby.h,rubysig.h... no
            checking for rb_thread_blocking_region()... no
            checking for inotify_init() in sys/inotify.h... yes
            checking for writev() in sys/uio.h... yes
            checking for rb_thread_check_ints()... yes
            checking for rb_time_new()... yes
            checking for sys/event.h... no
            checking for epoll_create() in sys/epoll.h... yes
            creating Makefile
            
            To see why this extension failed to compile, please check the mkmf.log which can be found here:
            
            /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/extensions/x86_64-linux/2.3.0/eventmachine-1.0.0/mkmf.log
            
            current directory:
            /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/eventmachine-1.0.0/ext
            make "DESTDIR=" clean
            
            current directory:
            /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/eventmachine-1.0.0/ext
            make "DESTDIR="
            compiling binder.cpp
            compiling cmain.cpp
            compiling ed.cpp
            compiling em.cpp
            em.cpp: In member function ‘bool EventMachine_t::_RunEpollOnce()’:
            em.cpp:532:65: error: ‘rb_thread_select’ was not declared in this scope
              if ((ret = rb_thread_select(epfd + 1, &fdreads, NULL, NULL, &tv)) < 1) {
                                                                             ^
            em.cpp:573:37: error: ‘rb_thread_select’ was not declared in this scope
               EmSelect (0, NULL, NULL, NULL, &tv);
                                                 ^
            em.cpp: In member function ‘int SelectData_t::_Select()’:
            em.cpp:825:67: error: ‘rb_thread_select’ was not declared in this scope
              return EmSelect (maxsocket+1, &fdreads, &fdwrites, &fderrors, &tv);
                                                                               ^
            em.cpp: In member function ‘bool EventMachine_t::_RunSelectOnce()’:
            em.cpp:964:40: error: ‘rb_thread_select’ was not declared in this scope
                  EmSelect (0, NULL, NULL, NULL, &tv);
                                                    ^
            em.cpp: In member function ‘void EventMachine_t::SignalLoopBreaker()’:
            em.cpp:282:34: warning: ignoring return value of ‘ssize_t write(int, const void*, size_t)’, declared with attribute
            warn_unused_result [-Wunused-result]
              write (LoopBreakerWriter, "", 1);
                                              ^
            em.cpp: In member function ‘void EventMachine_t::_ReadLoopBreaker()’:
            em.cpp:1011:50: warning: ignoring return value of ‘ssize_t read(int, void*, size_t)’, declared with attribute
            warn_unused_result [-Wunused-result]
              read (LoopBreakerReader, buffer, sizeof(buffer));
                                                              ^
            Makefile:231: recipe for target 'em.o' failed
            make: *** [em.o] Error 1
            
            make failed, exit code 2
            
            Gem files will remain installed in
            /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/eventmachine-1.0.0 for
            inspection.
            Results logged to
            /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/extensions/x86_64-linux/2.3.0/eventmachine-1.0.0/gem_make.out
            
            An error occurred while installing eventmachine (1.0.0), and Bundler cannot continue.
            Make sure that `gem install eventmachine -v '1.0.0'` succeeds before bundling.
            $   
         
    - So, jaegerca said look at Gemfile.lock to see who's pulling in eventmachine

      Turns out it's "thin", so go to more recent version of "thin":

            -gem 'thin', '~> 1.3.1'
            +gem 'thin', '~> 1.7.0'

* Next error is with RMagick:

    - Here's what happened first:

      https://hastebin.com/axeyexolel.txt
     
            $ bundle install --path vendor/bundle
            Fetching gem metadata from http://rubygems.org/.............
            Fetching version metadata from http://rubygems.org/...
            Fetching dependency metadata from http://rubygems.org/..
            Resolving dependencies...
            Using rake 0.9.6
            Using Platform 0.4.0
            Using open4 1.3.0
            Using RedCloth 4.2.9
            Using multi_json 1.6.0
            Using builder 3.0.4
            Using i18n 0.6.1
            Using erubis 2.7.0
            Using rack 1.3.10
            Using hike 1.2.1
            Using tilt 1.3.3
            Using mime-types 1.21
            Using polyglot 0.3.3
            Using arel 2.2.3
            Using tzinfo 0.3.35
            Using addressable 2.2.8
            Using ansi 1.4.3
            Using bcrypt-ruby 3.0.1
            Using bundler 1.13.6
            Using cancan 1.6.9
            Using highline 1.6.15
            Using net-ssh 2.9.1
            Using nokogiri 1.5.6
            Using ffi 1.3.1
            Using rubyzip 0.9.9
            Using websocket 1.0.7
            Using hashie 2.1.2
            Using json 1.6.1 from source at `foo/json-1.6.1`
            Using mixlib-log 1.6.0
            Using diff-lcs 1.2.4
            Using mixlib-cli 1.5.0
            Using mixlib-config 2.2.1
            Using mixlib-shellout 1.6.1
            Using ipaddress 0.8.0
            Using systemu 2.5.2
            Using yajl-ruby 1.2.1
            Using coderay 1.1.0
            Using method_source 0.8.2
            Using slop 3.6.0
            Using chronic 0.3.0
            Using closure-compiler 1.1.8
            Using daemons 1.1.9
            Using fastercsv 1.5.5
            Using json_pure 1.8.6 (was 1.7.7)
            Using stringex 1.5.1
            Using uuidtools 2.1.3
            Using orm_adapter 0.0.7
            Using net-ldap 0.2.2
            Using thor 0.14.6
            Using dm-paperclip 2.4.1 from http://github.com/Snorby/dm-paperclip.git (at master@f3101cc)
            Using ruby-graphviz 1.0.8
            Installing eventmachine 1.2.3 (was 1.0.0) with native extensions
            Using pdfkit 0.4.6
            Using geoip 1.1.2
            Using getopt 1.4.1
            Using gmaps4rails 1.5.6
            Using home_run 1.0.7
            Using minitest 4.6.0
            Using moneta 0.6.0
            Using net-dns 0.6.1
            Using netaddr 1.5.0
            Using request_store 1.0.5
            Installing rmagick 2.13.2 with native extensions
            Using rspec-core 2.0.1
            Using simple_form 1.2.2
            Using snmp 1.1.0
            Using whois 2.7.0
            Using will_paginate 3.0.4
            Using POpen4 0.1.4
            Using activesupport 3.1.11
            Using rack-cache 1.2
            Using rack-mount 0.8.3
            Using rack-test 0.6.2
            Using warden 1.2.1
            Using rack-ssl 1.3.3
            Using puma 1.6.3
            Using sprockets 2.0.4
            Using rest-client 1.6.9
            Using treetop 1.4.12
            Using dm-core 1.2.0
            Using data_objects 0.10.12
            Using turn 0.9.6
            Using net-scp 1.0.4
            Using net-sftp 2.0.5
            Using net-ssh-gateway 1.1.0
            Using xpath 1.0.0
            Using childprocess 0.3.8
            Using rdoc 3.12.1
            Using chef-zero 2.0.2
            Using mixlib-authentication 1.3.0
            Using rspec-expectations 2.0.1
            Using ohai 7.0.4
            Using pry 0.10.3
            Installing thin 1.7.0 (was 1.3.1) with native extensions
            Using ezprint 0.2.0 from http://github.com/mephux/ezprint.git (at rails3@c231df7)
            Gem::Ext::BuildError: ERROR: Failed to build gem native extension.
            
            current directory:
            /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/rmagick-2.13.2/ext/RMagick
            /usr/bin/ruby2.3 -r ./siteconf20170513-15740-1dh8nbx.rb extconf.rb
            checking for Ruby version >= 1.8.5... yes
            checking for gcc... yes
            checking for Magick-config... no
            Can't install RMagick 2.13.2. Can't find Magick-config in
            /home/kfogel/perl5/bin:/home/kfogel/private/bin:/home/kfogel/bin:/usr/local/bin:/home/kfogel/perl5/bin:/home/kfogel/private/bin:/home/kfogel/bin:/usr/local/bin:/home/kfogel/perl5/bin:/home/kfogel/private/bin:/home/kfogel/bin:/usr/local/bin:/home/kfogel/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/bin:/usr/bin:/sbin:/usr/sbin:/usr/ucb:/usr/public/bin:/usr/games:/bin:/usr/bin:/sbin:/usr/sbin:/usr/ucb:/usr/public/bin:/usr/games:/bin:/usr/bin:/sbin:/usr/sbin:/usr/ucb:/usr/public/bin:/usr/games
            
            *** extconf.rb failed ***
            Could not create Makefile due to some reason, probably lack of necessary
            libraries and/or headers.  Check the mkmf.log file for more details.  You may
            need configuration options.
            
            Provided configuration options:
            	--with-opt-dir
            	--without-opt-dir
            	--with-opt-include
            	--without-opt-include=${opt-dir}/include
            	--with-opt-lib
            	--without-opt-lib=${opt-dir}/lib
            	--with-make-prog
            	--without-make-prog
            	--srcdir=.
            	--curdir
            	--ruby=/usr/bin/$(RUBY_BASE_NAME)2.3
            
            To see why this extension failed to compile, please check the mkmf.log which can be found here:
            
            /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/extensions/x86_64-linux/2.3.0/rmagick-2.13.2/mkmf.log
            
            extconf failed, exit code 1
            
            Gem files will remain installed in
            /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/rmagick-2.13.2 for inspection.
            Results logged to
            /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/extensions/x86_64-linux/2.3.0/rmagick-2.13.2/gem_make.out
            
            An error occurred while installing rmagick (2.13.2), and Bundler cannot continue.
            Make sure that `gem install rmagick -v '2.13.2'` succeeds before bundling.
            $ 
     
    - So 'apt-get install' a bunch of things, as per below
    
      (But probably only the last one mattered?)
    
        + libmagick-dev
        + libmagick++-dev
        + libmagickwand-dev
        + graphicsmagick-libmagick-dev-compat
        + graphicsmagick-imagemagick-compat

          The 'graphicsmagick-imagemagick-compat' install caused this:

                root@floss:/usr/include/ruby-2.3.0/ruby# apt-get install graphicsmagick-imagemagick-compat
                Reading package lists... Done
                Building dependency tree       
                Reading state information... Done
                The following packages were automatically installed and are no longer required:
                  cups-browsed cups-core-drivers cups-daemon cups-filters-core-drivers
                  cups-ppdc cups-server-common foomatic-db-compressed-ppds foomatic-db-engine
                  foomatic-filters gksu hp-ppd libcupscgi1 libcupsmime1 libcupsppdc1
                  libfontembed1 libgksu2-0 libgutenprint2 libhpmud0 libimage-magick-q16-perl
                  liblouisutdml-bin liblouisutdml-data liblouisutdml7 libmagick++-6-headers
                  libmagick++-6.q16-dev libqpdf17 libsane-hpaio mscompress openprinting-ppds
                  printer-driver-all printer-driver-brlaser printer-driver-c2050
                  printer-driver-c2esp printer-driver-cjet printer-driver-dymo
                  printer-driver-escpr printer-driver-foo2zjs printer-driver-foo2zjs-common
                  printer-driver-fujixerox printer-driver-hpijs printer-driver-m2300w
                  printer-driver-min12xxw printer-driver-pnm2ppa printer-driver-ptouch
                  printer-driver-pxljr printer-driver-sag-gdi python3-dbus.mainloop.pyqt5
                  python3-notify2 python3-pexpect python3-ptyprocess python3-pyqt5
                  python3-renderpm python3-reportlab python3-reportlab-accel qpdf
                  system-config-printer
                Use 'sudo apt autoremove' to remove them.
                The following additional packages will be installed:
                  foomatic-filters graphicsmagick
                Suggested packages:
                  graphicsmagick-dbg
                The following packages will be REMOVED:
                  cups cups-filters hpijs-ppds hplip hplip-gui imagemagick imagemagick-6.q16
                  printer-driver-gutenprint printer-driver-hpcups printer-driver-postscript-hp
                  printer-driver-splix task-print-server
                The following NEW packages will be installed:
                  foomatic-filters graphicsmagick graphicsmagick-imagemagick-compat
                0 upgraded, 3 newly installed, 12 to remove and 0 not upgraded.
                Need to get 1,040 kB of archives.
                After this operation, 18.4 MB disk space will be freed.
                Do you want to continue? [Y/n] y
                Get:1 http://ftp.us.debian.org/debian testing/main amd64 foomatic-filters amd64 4.0.17-9 [156 kB]
                Get:2 http://ftp.us.debian.org/debian testing/main amd64 graphicsmagick amd64 1.3.25-8 [858 kB]
                Get:3 http://ftp.us.debian.org/debian testing/main amd64 graphicsmagick-imagemagick-compat all 1.3.25-8 [26.1 kB]
                Fetched 1,040 kB in 0s (2,207 kB/s)
                debconf: unable to initialize frontend: Dialog
                debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
                debconf: falling back to frontend: Readline
                Preconfiguring packages ...
                (Reading database ... 519944 files and directories currently installed.)
                Removing task-print-server (3.39) ...
                Removing printer-driver-splix (2.0.0+svn315-6) ...
                Removing printer-driver-gutenprint (5.2.11-1+b2) ...
                Removing printer-driver-postscript-hp (3.16.11+repack0-3) ...
                Removing hpijs-ppds (3.16.11+repack0-3) ...
                dpkg: cups-filters: dependency problems, but removing anyway as you requested:
                 printer-driver-foo2zjs depends on cups-filters | foomatic-filters; however:
                  Package cups-filters is to be removed.
                  Package foomatic-filters is not installed.
                  Package cups-filters which provides foomatic-filters is to be removed.
                 printer-driver-pxljr depends on cups-filters (>= 1.0.42) | foomatic-filters (>= 4.0.0~bzr156); however:
                  Package cups-filters is to be removed.
                  Package foomatic-filters is not installed.
                  Package cups-filters which provides foomatic-filters is to be removed.
                 cups depends on cups-filters (>= 1.0.24-3~).
                 printer-driver-m2300w depends on cups-filters (>= 1.0.42) | foomatic-filters (>= 4.0.0~bzr156); however:
                  Package cups-filters is to be removed.
                  Package foomatic-filters is not installed.
                  Package cups-filters which provides foomatic-filters is to be removed.
                 printer-driver-hpcups depends on cups-filters (>= 1.0.36) | ghostscript-cups; however:
                  Package cups-filters is to be removed.
                  Package ghostscript-cups is not installed.
                  Package cups-filters which provides ghostscript-cups is to be removed.
                 foomatic-db-engine depends on cups-filters (>= 1.0.42) | foomatic-filters (>= 4.0); however:
                  Package cups-filters is to be removed.
                  Package foomatic-filters is not installed.
                  Package cups-filters which provides foomatic-filters is to be removed.
                 printer-driver-foo2zjs depends on cups-filters | foomatic-filters; however:
                  Package cups-filters is to be removed.
                  Package foomatic-filters is not installed.
                  Package cups-filters which provides foomatic-filters is to be removed.
                 printer-driver-pxljr depends on cups-filters (>= 1.0.42) | foomatic-filters (>= 4.0.0~bzr156); however:
                  Package cups-filters is to be removed.
                  Package foomatic-filters is not installed.
                  Package cups-filters which provides foomatic-filters is to be removed.
                 printer-driver-m2300w depends on cups-filters (>= 1.0.42) | foomatic-filters (>= 4.0.0~bzr156); however:
                  Package cups-filters is to be removed.
                  Package foomatic-filters is not installed.
                  Package cups-filters which provides foomatic-filters is to be removed.
                 foomatic-db-engine depends on cups-filters (>= 1.0.42) | foomatic-filters (>= 4.0); however:
                  Package cups-filters is to be removed.
                  Package foomatic-filters is not installed.
                  Package cups-filters which provides foomatic-filters is to be removed.
                 printer-driver-hpcups depends on cups-filters (>= 1.0.36) | ghostscript-cups; however:
                  Package cups-filters is to be removed.
                  Package ghostscript-cups is not installed.
                  Package cups-filters which provides ghostscript-cups is to be removed.
                
                Removing cups-filters (1.11.6-3) ...
                dpkg: cups: dependency problems, but removing anyway as you requested:
                 printer-driver-hpcups depends on cups.
                 printer-driver-hpcups depends on cups (>= 1.4.0) | cupsddk; however:
                  Package cups is to be removed.
                  Package cupsddk is not installed.
                 printer-driver-hpcups depends on cups.
                 printer-driver-hpcups depends on cups (>= 1.4.0) | cupsddk; however:
                  Package cups is to be removed.
                  Package cupsddk is not installed.
                 hplip depends on cups (>= 1.1.20).
                
                Removing cups (2.2.1-8) ...
                dpkg: hplip: dependency problems, but removing anyway as you requested:
                 hplip-gui depends on hplip (>= 3.16.11+repack0-3); however:
                  Package hplip is to be removed.
                
                Removing hplip (3.16.11+repack0-3) ...
                Removing printer-driver-hpcups (3.16.11+repack0-3) ...
                Selecting previously unselected package foomatic-filters.
                (Reading database ... 518883 files and directories currently installed.)
                Preparing to unpack .../foomatic-filters_4.0.17-9_amd64.deb ...
                Unpacking foomatic-filters (4.0.17-9) ...
                (Reading database ... 518909 files and directories currently installed.)
                Removing hplip-gui (3.16.11+repack0-3) ...
                Selecting previously unselected package graphicsmagick.
                (Reading database ... 518871 files and directories currently installed.)
                Preparing to unpack .../graphicsmagick_1.3.25-8_amd64.deb ...
                Unpacking graphicsmagick (1.3.25-8) ...
                (Reading database ... 518980 files and directories currently installed.)
                Removing imagemagick (8:6.9.7.4+dfsg-6) ...
                dpkg: imagemagick-6.q16: dependency problems, but removing anyway as you requested:
                 calibre depends on imagemagick; however:
                  Package imagemagick is not installed.
                  Package imagemagick-6.q16 which provides imagemagick is to be removed.
                 asymptote depends on imagemagick; however:
                  Package imagemagick is not installed.
                  Package imagemagick-6.q16 which provides imagemagick is to be removed.
                
                Removing imagemagick-6.q16 (8:6.9.7.4+dfsg-6) ...
                Selecting previously unselected package graphicsmagick-imagemagick-compat.
                (Reading database ... 518926 files and directories currently installed.)
                Preparing to unpack .../graphicsmagick-imagemagick-compat_1.3.25-8_all.deb ...
                Unpacking graphicsmagick-imagemagick-compat (1.3.25-8) ...
                Setting up foomatic-filters (4.0.17-9) ...
                debconf: unable to initialize frontend: Dialog
                debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
                debconf: falling back to frontend: Readline
                
                Creating config file /etc/foomatic/filter.conf with new version
                Processing triggers for mime-support (3.60) ...
                Processing triggers for desktop-file-utils (0.23-1) ...
                Processing triggers for man-db (2.7.6.1-2) ...
                Processing triggers for gnome-menus (3.13.3-9) ...
                Processing triggers for dbus (1.10.18-1) ...
                Setting up graphicsmagick (1.3.25-8) ...
                Processing triggers for hicolor-icon-theme (0.15-1) ...
                Setting up graphicsmagick-imagemagick-compat (1.3.25-8) ...
                root@floss:/usr/include/ruby-2.3.0/ruby#   

        + libmagickcore-dev

          Which caused this:

                root@floss:/usr/include/ruby-2.3.0/ruby# apt-get install libmagickcore-dev
                Reading package lists... Done
                Building dependency tree       
                Reading state information... Done
                The following packages were automatically installed and are no longer required:
                  cups-browsed cups-core-drivers cups-daemon cups-filters-core-drivers
                  cups-ppdc cups-server-common foomatic-db-compressed-ppds foomatic-db-engine
                  foomatic-filters gksu hp-ppd libcupscgi1 libcupsmime1 libcupsppdc1
                  libfontembed1 libgksu2-0 libgraphics-magick-perl libgraphicsmagick++-q16-12
                  libgraphicsmagick++1-dev libgraphicsmagick1-dev libgutenprint2 libhpmud0
                  libimage-magick-q16-perl liblouisutdml-bin liblouisutdml-data liblouisutdml7
                  libmagick++-6-headers libmagick++-6.q16-dev libqpdf17 libsane-hpaio
                  mscompress openprinting-ppds printer-driver-all printer-driver-brlaser
                  printer-driver-c2050 printer-driver-c2esp printer-driver-cjet
                  printer-driver-dymo printer-driver-escpr printer-driver-foo2zjs
                  printer-driver-foo2zjs-common printer-driver-fujixerox printer-driver-hpijs
                  printer-driver-m2300w printer-driver-min12xxw printer-driver-pnm2ppa
                  printer-driver-ptouch printer-driver-pxljr printer-driver-sag-gdi
                  python3-dbus.mainloop.pyqt5 python3-notify2 python3-pexpect
                  python3-ptyprocess python3-pyqt5 python3-renderpm python3-reportlab
                  python3-reportlab-accel qpdf system-config-printer
                Use 'sudo apt autoremove' to remove them.
                The following packages will be REMOVED:
                  graphicsmagick-libmagick-dev-compat
                The following NEW packages will be installed:
                  libmagickcore-dev
                0 upgraded, 1 newly installed, 1 to remove and 0 not upgraded.
                Need to get 1,252 B of archives.
                After this operation, 61.4 kB disk space will be freed.
                Do you want to continue? [Y/n] y
                Get:1 http://ftp.us.debian.org/debian testing/main amd64 libmagickcore-dev all 8:6.9.7.4+dfsg-6 [1,252 B]
                Fetched 1,252 B in 0s (11.9 kB/s)
                debconf: unable to initialize frontend: Dialog
                debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
                debconf: falling back to frontend: Readline
                (Reading database ... 518946 files and directories currently installed.)
                Removing graphicsmagick-libmagick-dev-compat (1.3.25-8) ...
                Selecting previously unselected package libmagickcore-dev.
                (Reading database ... 518927 files and directories currently installed.)
                Preparing to unpack .../libmagickcore-dev_8%3a6.9.7.4+dfsg-6_all.deb ...
                Unpacking libmagickcore-dev (8:6.9.7.4+dfsg-6) ...
                Setting up libmagickcore-dev (8:6.9.7.4+dfsg-6) ...
                Processing triggers for man-db (2.7.6.1-2) ...
                root@floss:/usr/include/ruby-2.3.0/ruby# 
  
        + libmagick-dev

* Finally, stopped doing libmagick dev libs, and just bumped rmagick in Gemfile:

  The libmagic dev / rmagick stuff may have helped, but this was also needed:

        -gem 'rmagick',                     '~> 2.13.1'
        +gem 'rmagick',                     '~> 2.16.0'

* Fix mysql build error

  Got this error:

        Using delayed_job_data_mapper 1.0.0.rc from https://github.com/Snorby/delayed_job_data_mapper.git (at master@6f1c4a8)
        Gem::Ext::BuildError: ERROR: Failed to build gem native extension.
        
        current directory:
        /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/do_mysql-0.10.12/ext/do_mysql
        /usr/bin/ruby2.3 -r ./siteconf20170513-22052-1p4do30.rb extconf.rb
        checking for mysql_query() in -lmysqlclient... no
        *** extconf.rb failed ***

  The solution was:

        $ sudo apt-get install default-libmysqlclient-dev

  (which would be 'libmysqlclient-dev' anywhere but Debian 'testing').

* And that brings us to here:

        $ rake snorby:setup
          /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/activesupport-3.1.11/lib/active_support/values/time_zone.rb:270: warning: circular argument reference - now
          rake aborted!
          LoadError: /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/do_mysql-0.10.12/lib/do_mysql/do_mysql.so: undefined symbol: rb_thread_select - /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/do_mysql-0.10.12/lib/do_mysql/do_mysql.so
          /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/do_mysql-0.10.12/lib/do_mysql.rb:29:in `require'
          /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/do_mysql-0.10.12/lib/do_mysql.rb:29:in `<top (required)>'
          /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/dm-mysql-adapter-1.2.0/lib/dm-mysql-adapter/adapter.rb:1:in `require'
          /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/dm-mysql-adapter-1.2.0/lib/dm-mysql-adapter/adapter.rb:1:in `<top (required)>'
          /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/dm-mysql-adapter-1.2.0/lib/dm-mysql-adapter.rb:1:in `require'
          /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/vendor/bundle/ruby/2.3.0/gems/dm-mysql-adapter-1.2.0/lib/dm-mysql-adapter.rb:1:in `<top (required)>'
          /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/config/application.rb:13:in `<top (required)>'
          /home/kfogel/private/work/ots/clients/onshore/r/onshore-snorby/Rakefile:4:in `<top (required)>'
          (See full trace by running task with --trace)
        $ 