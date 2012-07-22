Errplane
========

This gem integrates your applications with [Errplane](http://errplane.com), a cloud-based tool for handling exceptions, log aggregation, uptime monitoring, and alerting.

This gem currently has support for Ruby on Rails (3.x), Sinatra, Resque, and Capistrano.

Support
-------

Running into any issues? Get in touch with us at [support@errplane.com](mailto:support@errplane.com).

Ruby on Rails Installation
--------------------------

Start by adding the gem to your Gemfile:

    gem "errplane"

Then, issue the following commands in your application's root directory:

    bundle
    rails g errplane --api-key your-api-key-goes-here

This will create `config/initializers/errplane.rb` for you automatically. If you want to make sure that everything's working correctly, just run:

    bundle exec rake errplane:test

You should be able to view the exception at [http://errplane.com](http://errplane.com) and also receive an email notification of the test exception.

Capistrano Integration
----------------------

In your `config/deploy.rb`, add the following line:

    require 'errplane/capistrano'

This will automatically pull your API key from the Rails initializer and notify Errplane of every deployment.

Resque Integration With Multiple Failure Backends
-------------------------------------------------

This gem also supports notifications from failed Resque jobs. Just add the following to the an initializer, such as `config/initializers/resque.rb`:

    require 'resque/failure/multiple'
    require 'resque/failure/redis'
    require 'errplane/resque'

    Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Errplane]
    Resque::Failure.backend = Resque::Failure::Multiple

Assuming this is running from within a normal Rails project, the values provided in `config/initializers/errplane.rb` will make sure that the Resque backend is set up correctly.

Customizing How Exceptions Get Grouped and Sending Additional Data
------------------------------------------------------------------

The Errplane API will automatically attempt to group exceptions and threshold alerts based on a SHA hash of the exception class name and the first line of the backtrace. This works for some cases, but may be too noisy for failures that occur in different spots in your application that mean the same thing. This gem includes functionality to define a hash yourself to modify how exception groupings are made. That can be done by modifying `config/initializers/resque.rb`:

    require 'digest/sha1'

    Errplane.configure do |config|
      config.define_custom_exception_data do |black_box|
        if black_box.exception.class ==  ZeroDivisionError
          black_box.hash = Digest::SHA1.hexdigest("ZeroDivisionError")
          black_box.custom_data[:extra_info] = "maths"
        end
      end
    end

That example will ensure that any divide by zero errors in your application will be grouped together, while all other exceptions will be grouped by the normal logic. The custom_exception_data block gets yielded an [Errplane::BlackBox](https://github.com/errplane/gem/blob/master/lib/errplane/black_box.rb) object. Through that object you can access exception information, request information, and custom data. You can also add custom data that can be viewed later in Errplane. This is useful if you want to capture additional context that we haven't already thought of including. When setting `custom_data.hash` it should always be some sort of digest like SHA1 used in the above example.

Rails Remote Logger
-------------------

This gem supports remotely sending rails logs to Errplane to be alerted and monitored in our web console. To use this, run the generator above and uncomment the following line in `config/initializers/errplane.rb`.

    # config.syslogd_port = "<port here>"

Chef Support
------------

We currently only support Exception notification on Chef, we will be releasing remote logging for chef soon. See our wiki(https://github.com/errplane/docs/wiki/Chef-Integration) for details.



Contributing
------------

We love contributions. Want to add support for something you don't already see here? Fork this repository and send us a pull request.

Copyright
---------

Copyright (c) 2012 Errplane, Inc.
