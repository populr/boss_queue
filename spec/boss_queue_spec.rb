require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "BossQueue module" do
  before(:each) do
    BossQueue.environment = 'test'

    BossQueue::Job.any_instance.stub(:queue_name=)
    BossQueue::Job.any_instance.stub(:failure_action=)
    BossQueue::Job.any_instance.stub(:failure_callback=)
    BossQueue::Job.any_instance.stub(:delete_if_target_missing=)
    BossQueue::Job.any_instance.stub(:model_class_name=)
    BossQueue::Job.any_instance.stub(:model_id=)
    BossQueue::Job.any_instance.stub(:callback=)
    BossQueue::Job.any_instance.stub(:args=)
    BossQueue::Job.any_instance.stub(:save!)
    BossQueue::Job.any_instance.stub(:enqueue)
    BossQueue::Job.any_instance.stub(:enqueue_with_delay)
  end

  it "should respond to environment" do
    BossQueue.should respond_to(:environment)
  end

  it "should respond to environment=" do
    BossQueue.should respond_to(:environment=)
  end

  describe "#failure_action" do
    it "should default to 'retry'" do
      BossQueue.new.failure_action.should == 'retry'
    end

    it "should be overridable by a :failure_action option on initialize" do
      BossQueue.new(:failure_action => 'none').failure_action.should == 'none'
    end
  end

  describe "#table_name" do
    before(:each) do
      BossQueue.environment = nil
    end

    context "when @@environment is 'development'" do
      it "should be 'dev_boss_queue_jobs'" do
        BossQueue.environment = 'development'
        BossQueue.new.table_name.should == 'dev_boss_queue_jobs'
      end
    end

    context "when @@environment is 'production'" do
      it "should be 'boss_queue_jobs'" do
        BossQueue.environment = 'production'
        BossQueue.new.table_name.should == 'boss_queue_jobs'
      end
    end

    context "when @@environment is 'staging'" do
      it "should be 'staging_boss_queue_jobs'" do
        BossQueue.environment = 'staging'
        BossQueue.new.table_name.should == 'staging_boss_queue_jobs'
      end
    end

    context "when @@environment is 'staging'" do
      it "should be 'staging_boss_queue_jobs'" do
        BossQueue.environment = 'staging'
        BossQueue.new.table_name.should == 'staging_boss_queue_jobs'
      end
    end

    context "when @@environment is nil" do
      it "should raise an exception" do
        lambda {
          BossQueue.new.table_name
        }.should raise_error
      end
    end
  end


  describe "#queue_name" do
    before(:each) do
      BossQueue.environment = nil
    end

    context "when @@environment is 'development'" do
      it "should be 'dev_boss_queue'" do
        BossQueue.environment = 'development'
        BossQueue.new.queue_name.should == 'dev_boss_queue'
      end
    end

    context "when @@environment is 'production'" do
      it "should be 'boss_queue'" do
        BossQueue.environment = 'production'
        BossQueue.new.queue_name.should == 'boss_queue'
      end
    end

    context "when @@environment is 'staging'" do
      it "should be 'staging_boss_queue'" do
        BossQueue.environment = 'staging'
        BossQueue.new.queue_name.should == 'staging_boss_queue'
      end
    end

    context "when @@environment is 'staging'" do
      it "should be 'staging_boss_queue'" do
        BossQueue.environment = 'staging'
        BossQueue.new.queue_name.should == 'staging_boss_queue'
      end
    end

    context "when @@environment is nil" do
      it "should raise an exception" do
        lambda {
          BossQueue.new.queue_name
        }.should raise_error
      end
    end

    context "when a queue option is included in the initializer" do
      it "should append that to the queue name" do
        BossQueue.environment = 'production'
        BossQueue.new(:queue => 'emails').queue_name.should == 'boss_queue_emails'
      end
    end
  end

  describe "#enqueue" do
    before(:each) do
      @arguments = ['a', 'b', { 'c' => 2, 'd' => 1 }]
      @argument_json = JSON.generate(@arguments)

      class TestClass
        def id
          'xyz'
        end

        def self.test_class_method
        end

        def test_instance_method
        end
      end
    end

    context "when a class" do
      it "should initialize a new BossQueue::Job object, save and call enqueue on it" do
        queue = BossQueue.new
        BossQueue::Job.any_instance.should_receive(:queue_name=).with('test_boss_queue')
        BossQueue::Job.any_instance.should_receive(:failure_action=).with('retry')
        BossQueue::Job.any_instance.should_receive(:model_class_name=).with('TestClass')
        BossQueue::Job.any_instance.should_not_receive(:model_id=)
        BossQueue::Job.any_instance.should_receive(:callback=).with('test_class_method')
        BossQueue::Job.any_instance.should_receive(:args=).with(@argument_json)
        BossQueue::Job.any_instance.should_receive(:save!)
        BossQueue::Job.any_instance.should_receive(:enqueue)
        queue.enqueue(TestClass, :test_class_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
      end
    end

    context "when a class instance" do
      it "should initialize a new BossQueue::Job object, save and call enqueue on it" do
        queue = BossQueue.new
        BossQueue::Job.any_instance.should_receive(:queue_name=).with('test_boss_queue')
        BossQueue::Job.any_instance.should_receive(:failure_action=).with('retry')
        BossQueue::Job.any_instance.should_receive(:model_class_name=).with('TestClass')
        BossQueue::Job.any_instance.should_receive(:model_id=).with('xyz')
        BossQueue::Job.any_instance.should_receive(:callback=).with('test_instance_method')
        BossQueue::Job.any_instance.should_receive(:args=).with(@argument_json)
        BossQueue::Job.any_instance.should_receive(:save!)
        BossQueue::Job.any_instance.should_receive(:enqueue)
        queue.enqueue(TestClass.new, :test_instance_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
      end
    end

    context "when failure_action is 'callback'" do
      it "should set the job failure_callback to the failure_callback option" do
        queue = BossQueue.new(:failure_action => 'callback', :failure_callback => :call_if_failed)
        BossQueue::Job.any_instance.should_receive(:failure_callback=).with('call_if_failed')
        queue.enqueue(TestClass, :test_class_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
      end
    end

    context "when delete_if_target_missing option is true" do
      it "should set delete_if_target_missing on the job" do
        queue = BossQueue.new(:delete_if_target_missing => true)
        BossQueue::Job.any_instance.should_receive(:delete_if_target_missing=).with(true)
        queue.enqueue(TestClass, :test_class_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
      end
    end

  end

  describe "#enqueue_with_delay" do
    before(:each) do
      @arguments = ['a', 'b', { 'c' => 2, 'd' => 1 }]
      @argument_json = JSON.generate(@arguments)
    end

    context "when a class" do
      it "should initialize a new BossQueue::Job object, save and call enqueue on it" do
        queue = BossQueue.new
        BossQueue::Job.any_instance.should_receive(:queue_name=).with('test_boss_queue')
        BossQueue::Job.any_instance.should_receive(:failure_action=).with('retry')
        BossQueue::Job.any_instance.should_receive(:model_class_name=).with('TestClass')
        BossQueue::Job.any_instance.should_not_receive(:model_id=)
        BossQueue::Job.any_instance.should_receive(:callback=).with('test_class_method')
        BossQueue::Job.any_instance.should_receive(:args=).with(@argument_json)
        BossQueue::Job.any_instance.should_receive(:save!)
        BossQueue::Job.any_instance.should_receive(:enqueue_with_delay).with(60)
        queue.enqueue_with_delay(60, TestClass, :test_class_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
      end
    end

    context "when a class instance" do
      it "should initialize a new BossQueue::Job object, save and call enqueue on it" do
        queue = BossQueue.new
        BossQueue::Job.any_instance.should_receive(:queue_name=).with('test_boss_queue')
        BossQueue::Job.any_instance.should_receive(:failure_action=).with('retry')
        BossQueue::Job.any_instance.should_receive(:model_class_name=).with('TestClass')
        BossQueue::Job.any_instance.should_receive(:model_id=).with('xyz')
        BossQueue::Job.any_instance.should_receive(:callback=).with('test_instance_method')
        BossQueue::Job.any_instance.should_receive(:args=).with(@argument_json)
        BossQueue::Job.any_instance.should_receive(:save!)
        BossQueue::Job.any_instance.should_receive(:enqueue_with_delay).with(60)
        queue.enqueue_with_delay(60, TestClass.new, :test_instance_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
      end
    end

    context "when failure_action is 'callback'" do
      it "should set the job failure_callback to the failure_callback option" do
        queue = BossQueue.new(:failure_action => 'callback', :failure_callback => :call_if_failed)
        BossQueue::Job.any_instance.should_receive(:failure_callback=).with('call_if_failed')
        queue.enqueue_with_delay(60, TestClass, :test_class_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
      end
    end

    context "when delete_if_target_missing option is true" do
      it "should set delete_if_target_missing on the job" do
        queue = BossQueue.new(:delete_if_target_missing => true)
        BossQueue::Job.any_instance.should_receive(:delete_if_target_missing=).with(true)
        queue.enqueue_with_delay(60, TestClass, :test_class_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
      end
    end

  end

  describe "#work" do
    before(:each) do
      @sqs_queue = double('queue')
      @sqs_queues = double('queues')
      @sqs_queues.stub(:[]).and_return(@sqs_queue)
      BossQueue.stub(:sqs_queues).and_return(@sqs_queues)
      BossQueue.stub(:sqs_queue_url).and_return('queue_url')

      @sqs_message = double('message')
      @sqs_message.stub(:body).and_return('ijk')
      @sqs_queue.stub(:receive_message)

      @job = double('job')
      @job.stub(:work)
      @job.stub(:sqs_queue=)
      BossQueue::Job.stub(:find_by_id).and_return(@job)
    end

    it "should dequeue from SQS using the value of sqs_queue_url" do
      @sqs_queue.should_receive(:receive_message).and_yield(@sqs_message)
      BossQueue.new.work
    end

    context "when something is dequeued from SQS" do
      before(:each) do
        @sqs_queue.should_receive(:receive_message).and_yield(@sqs_message)
      end

      it "should use the dequeued id to retrieve a BossQueue::Job object" do
        shard = double('shard')
        BossQueue::Job.should_receive(:find_by_id).with('ijk', :shard => BossQueue.new.table_name, :consistent_read => true).and_return(@job)
        BossQueue.new.work
      end

      context "when the dequeued id does not match a BossQueue::Job object" do
        it "should not raise an exception" do
          BossQueue::Job.stub(:find_by_id).and_raise(AWS::Record::RecordNotFound.new)
          lambda {
            BossQueue.new.work
          }.should_not raise_error
        end
      end

      it "should set the sqs_queue of the job since we already did the work of retrieving it's url" do
        @job.should_receive(:sqs_queue=).with(@sqs_queue)
        BossQueue.new.work
      end

      it "should call work on the BossQueue::Job object" do
        @job.should_receive(:work)
        BossQueue.new.work
      end

      it "should return true" do
        BossQueue.new.work.should be_true
      end
    end

    context "when nothing is dequeued from SQS" do
      it "should return false" do
        BossQueue.new.work.should be_false
      end
    end
  end

end
