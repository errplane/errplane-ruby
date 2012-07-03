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

This gem also supports notifications from failed Resque jobs. Just add the following to the an initializer:

    require 'resque/failure/multiple'
    require 'resque/failure/redis'
    require 'errplane/resque'

    Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Errplane]
    Resque::Failure.backend = Resque::Failure::Multiple

Don't forget that you can refer to `config/initializers/errplane.rb` for the relevant configuration values.

Contributing
------------

We love contributions. Want to add support for something you don't already see here? Fork this repository and send us a pull request.

Copyright
---------

Copyright (c) 2012 Errplane, Inc.
