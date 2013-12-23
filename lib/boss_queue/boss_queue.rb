require 'json'

class BossQueue
  @@environment = nil

  def initialize(options={})
    @failure_action = options[:failure_action] if options[:failure_action]
    @failure_callback = options[:failure_callback] if options[:failure_callback]
    @delete_if_target_missing = options[:delete_if_target_missing] if options[:delete_if_target_missing]
    @queue_postfix = options[:queue] ? '_' + options[:queue] : ''
  end

  def self.environment=(env)
    @@environment = env
  end

  def failure_action
    @failure_action ||= 'retry'
  end

  def failure_callback
    @failure_callback
  end

  def delete_if_target_missing
    @delete_if_target_missing
  end

  def table_name
    "#{BossQueue.queue_prefix}boss_queue_jobs"
  end

  def queue_name
    "#{BossQueue.queue_prefix}boss_queue#{@queue_postfix}"
  end


  def create_table(read_capacity=1, write_capacity=1, options={})
    create_opts = {}
    create_opts[:hash_key] = { :id => :string }

    AWS::DynamoDB.new.tables.create(table_name, read_capacity, write_capacity, create_opts)
  end

  def create_queue
    # small message size because we are only sending id
    # minimum 1 second delay so that we don't even try to pick it up until it is likely that the
    # message is ready (or else we waste time just waiting for the saved data to become available)
    AWS::SQS::QueueCollection.new.create(queue_name, :visibility_timeout => 180,
                                                     :maximum_message_size => 1024,
                                                     :delay_seconds => 1,
                                                     :message_retention_period => 1209600)
  end

  def work
    job_dequeued = false
    sqs_queue.receive_message do |job_id|
      job_dequeued = true
      # When a block is given, each message is yielded to the block and then deleted as long as the block exits normally - http://docs.aws.amazon.com/AWSRubySDK/latest/frames.html
      begin
        job = BossQueue::Job.find_by_id(job_id.body, :shard => table_name, :consistent_read => true)
        job.sqs_queue = sqs_queue
        job.work
      rescue AWS::Record::RecordNotFound
      end
    end
    job_dequeued
  end

  def enqueue(class_or_instance, callback_method, *args)
    job = create_job(class_or_instance, callback_method, *args)
    job.enqueue
  end

  def enqueue_with_delay(delay, class_or_instance, callback_method, *args)
    job = create_job(class_or_instance, callback_method, *args)
    job.enqueue_with_delay(delay)
  end

  def create_job(class_or_instance, callback_method, *args) # :nodoc:
    job = BossQueue::Job.shard(table_name).new
    if class_or_instance.is_a?(Class)
      class_name = class_or_instance.to_s
      instance_id = nil
    else
      class_name = class_or_instance.class.to_s
      instance_id = class_or_instance.id
    end
    job.queue_name = queue_name
    job.failure_action = failure_action
    job.failure_callback = failure_callback.to_s if failure_action == 'callback' && failure_callback
    job.delete_if_target_missing = delete_if_target_missing if delete_if_target_missing
    job.model_class_name = class_name
    job.model_id = instance_id unless instance_id.nil?
    job.callback = callback_method.to_s
    job.args = JSON.generate(args)
    job.save!
    job
  end

  def sqs_queue # :nodoc:
    @sqs_queue ||= BossQueue.sqs_queues[BossQueue.sqs_queue_url(queue_name)]
  end

  def self.sqs_queues # :nodoc:
    @sqs_queues ||= AWS::SQS.new.queues
  end

  def self.sqs_queue_url(name) # :nodoc:
    @url_mapping ||= {}
    @url_mapping[name] ||= BossQueue.sqs_queues.url_for(name)
  end

  def self.environment # :nodoc:
    @@environment ||= if Module.const_get('Rails')
                        Rails.env
                      elsif Module.const_get('Rack')
                        Rack.env
                      else
                        raise 'BossQueue requires an environment'
                      end
  end

  def self.queue_prefix # :nodoc:
    case self.environment
    when 'production'
      ''
    when 'development'
      'dev_'
    else
      environment + '_'
    end
  end

end
