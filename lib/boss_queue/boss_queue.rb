require 'json'

class BossQueue
  @@environment = nil

  def initialize(options={})
    @failure_action = options[:failure_action] if options[:failure_action]
    @queue_postfix = options[:queue] ? '_' + options[:queue] : ''
  end

  def self.environment=(env)
    @@environment = env
  end

  def failure_action
    @failure_action ||= 'retry'
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
    AWS::SQS::QueueCollection.new.create(queue_name, :default_visibility_timeout => 5 * 60)
  end

  def work
    work_done = false
    sqs_queue.receive_message do |job_id|
      # When a block is given, each message is yielded to the block and then deleted as long as the block exits normally - http://docs.aws.amazon.com/AWSRubySDK/latest/frames.html
      begin
        job = BossQueue::Job.shard(table_name).find(job_id.body)
        job.sqs_queue = sqs_queue
        job.work
        work_done = true
      rescue AWS::Record::RecordNotFound
      end
    end
    work_done
  end

  def enqueue(class_or_instance, method_name, *args)
    job = create_job(class_or_instance, method_name, *args)
    job.enqueue
  end

  def enqueue_with_delay(delay, class_or_instance, method_name, *args)
    job = create_job(class_or_instance, method_name, *args)
    job.enqueue_with_delay(delay)
  end

  def create_job(class_or_instance, method_name, *args) # :nodoc:
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
    job.queue_name = queue_name
    job.failure_action = failure_action
    job.model_class_name = class_name
    job.model_id = instance_id unless instance_id.nil?
    job.job_method = method_name.to_s
    job.job_arguments = JSON.generate(args)
    job.save!
    job
  end

  def sqs_queue # :nodoc:
    @sqs_queue ||= AWS::SQS.new.queues[AWS::SQS.new.queues.url_for(queue_name)]
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
