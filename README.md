boss_queue
==========

A fault tolerant job queue built around Amazon SQS &amp; DynamoDB


Setup
============

In your Gemfile:

    gem 'boss_queue'


boss_queue uses an Amazon SQS queue and a Amazon DynamoDB table for each environment (production, staging, test). To set these up in Rails do:

    $ rails c

    AWS.config(:access_key_id => <access_key_id>,
               :secret_access_key => <secret_access_key>)

    queue = BossQueue.new # default queue name
    # or
    queue = BossQueue.new(:queue => 'emails') # customized queue name (so you can have separate job queues)

    BossQueue.environment = 'development'
    queue.create_table
    queue.create_queue

    BossQueue.environment = 'staging'
    queue.create_table
    queue.create_queue

    # BossQueue.create_table(read_capacity, write_capacity)
    # One read capacity unit = two eventually consistent reads per second, for items up 4 KB in size.
    # One write capacity unit = one write per second, for items up to 1 KB in size.

    BossQueue.environment = 'production'
    queue.create_table(50, 10)
    queue.create_queue


Alternatively, in each of the respective environments, do:

    $ rails c

    AWS.config(:access_key_id => <access_key_id>,
               :secret_access_key => <secret_access_key>)

    # environment does not need to be set because it is taken from Rails.env
    BossQueue.create_table
    BossQueue.create_queue


Or these could be put into a migration.


Usage
=====

    myobject = MyClass.new
    # default failure action is 'retry' which retries up to four times
    queue = BossQueue.new(:failure_action => 'none', :queue => 'emails')

    # can enqueue instance methods (assumes that objects have an id and a #find(id) method)
    queue.enqueue(myobject, :method_to_execute, arg1, arg2)
    # enqueue with a delay of up to 900 seconds (15 minutes)
    queue.enqueue_with_delay(60, myobject, :method_to_execute, arg1, arg2, arg3)

    # can enqueue class methods
    queue.enqueue(MyClass, :method_to_execute)
    queue.enqueue_with_delay(60, MyClass, :method_to_execute, arg1, arg2)

    queue.work

    # failures are left in the DynamoDB table with the failed boolean set to true

BossQueue does not at present have a daemon component such as Sidekiq or Resque.


Future Work
===========

Create some mechanism for viewing failed jobs (and perhaps queued jobs...they are all in the same table)


