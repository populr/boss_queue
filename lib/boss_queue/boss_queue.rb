require 'json'

class BossQueue
  @@environment

  def self.environment=(env)
    @@environment = env
  end

  @@failure_action

  def self.failure_action
    @@failure_action ||= 'retry'
  end

  def self.failure_action=(env)
    @@failure_action = env
  end


  def self.table_name
    "#{self.queue_prefix}boss_queue_jobs"
  end

  def self.queue_name
    "#{self.queue_prefix}boss_queue"
  end


  def self.create_table(read_capacity=1, write_capacity=1, options={})
    create_opts = {}
    create_opts[:hash_key] = { :id => :string }
    create_opts[:range_key] = { :kind => :string }

    AWS::DynamoDB.new.tables.create(self.table_name, read_capacity, write_capacity, create_opts)
  end

  def self.create_queue
    AWS::SQS::QueueCollection.new.create(self.queue_name, :default_visibility_timeout => 5 * 60)
  end

  def self.work
    self.sqs_queue.receive_message do |job_id|
      # When a block is given, each message is yielded to the block and then deleted as long as the block exits normally - http://docs.aws.amazon.com/AWSRubySDK/latest/frames.html
      job = BossQueue::Job.shard(table_name).find(job_id.body)
      job.queue_name = self.queue_name
      job.work
    end
  end

  def self.enqueue(class_or_instance, method_name, *args)
    job = self.create_job(class_or_instance, method_name, *args)
    job.enqueue
  end

  def self.enqueue_with_delay(delay, class_or_instance, method_name, *args)
    job = self.create_job(class_or_instance, method_name, *args)
    job.enqueue_with_delay(delay)
  end

  def self.create_job(class_or_instance, method_name, *args) # :nodoc:
    job = BossQueue::Job.shard(table_name).new
    if class_or_instance.is_a?(Class)
      class_name = class_or_instance.to_s
      instance_id = nil
      job.kind = "#{class_name}@#{method_name}"
    else
      class_name = class_or_instance.class.to_s
      instance_id = class_or_instance.id
      job.kind = "#{class_name}##{method_name}"
    end
    job.queue_name = self.queue_name
    job.failure_action = self.failure_action
    job.model_class_name = class_name
    job.model_id = instance_id unless instance_id.nil?
    job.job_method = method_name.to_s
    job.job_arguments = JSON.generate(args)
    job.save!
    job
  end

  def self.sqs_queue # :nodoc:
    AWS::SQS.new.queues[AWS::SQS.new.queues.url_for(self.queue_name)]
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
