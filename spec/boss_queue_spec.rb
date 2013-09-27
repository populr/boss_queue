require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "BossQueue module" do

  it "should respond to environment" do
    BossQueue.should respond_to(:environment)
  end

  it "should respond to environment=" do
    BossQueue.should respond_to(:environment=)
  end

  it "should respond to failure_action" do
    BossQueue.should respond_to(:failure_action)
  end

  it "should respond to failure_action=" do
    BossQueue.should respond_to(:failure_action=)
  end

  describe "#failure_action" do
    it "should default to 'retry'" do
      BossQueue.failure_action.should == 'retry'
    end
  end

  describe "#table_name" do
    before(:each) do
      BossQueue.environment = nil
    end

    context "when @@environment is 'development'" do
      it "should be 'dev_boss_queue_jobs'" do
        BossQueue.environment = 'development'
        BossQueue.table_name.should == 'dev_boss_queue_jobs'
      end
    end

    context "when @@environment is 'production'" do
      it "should be 'boss_queue_jobs'" do
        BossQueue.environment = 'production'
        BossQueue.table_name.should == 'boss_queue_jobs'
      end
    end

    context "when @@environment is 'staging'" do
      it "should be 'staging_boss_queue_jobs'" do
        BossQueue.environment = 'staging'
        BossQueue.table_name.should == 'staging_boss_queue_jobs'
      end
    end

    context "when @@environment is 'staging'" do
      it "should be 'staging_boss_queue_jobs'" do
        BossQueue.environment = 'staging'
        BossQueue.table_name.should == 'staging_boss_queue_jobs'
      end
    end

    context "when @@environment is nil" do
      it "should raise an exception" do
        lambda {
          BossQueue.table_name
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
        BossQueue.queue_name.should == 'dev_boss_queue'
      end
    end

    context "when @@environment is 'production'" do
      it "should be 'boss_queue'" do
        BossQueue.environment = 'production'
        BossQueue.queue_name.should == 'boss_queue'
      end
    end

    context "when @@environment is 'staging'" do
      it "should be 'staging_boss_queue'" do
        BossQueue.environment = 'staging'
        BossQueue.queue_name.should == 'staging_boss_queue'
      end
    end

    context "when @@environment is 'staging'" do
      it "should be 'staging_boss_queue'" do
        BossQueue.environment = 'staging'
        BossQueue.queue_name.should == 'staging_boss_queue'
      end
    end

    context "when @@environment is nil" do
      it "should raise an exception" do
        lambda {
          BossQueue.queue_name
        }.should raise_error
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
        BossQueue.environment = 'test'
        BossQueue.failure_action = 'retry'
        BossQueue::Job.any_instance.should_receive(:kind=).with('TestClass@test_class_method')
        BossQueue::Job.any_instance.should_receive(:queue_name=).with('test_boss_queue')
        BossQueue::Job.any_instance.should_receive(:failure_action=).with('retry')
        BossQueue::Job.any_instance.should_receive(:model_class_name=).with('TestClass')
        BossQueue::Job.any_instance.should_not_receive(:model_id=)
        BossQueue::Job.any_instance.should_receive(:job_method=).with('test_class_method')
        BossQueue::Job.any_instance.should_receive(:job_arguments=).with(@argument_json)
        BossQueue::Job.any_instance.should_receive(:save)
        BossQueue::Job.any_instance.should_receive(:enqueue)
        BossQueue.enqueue(TestClass, :test_class_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
      end
    end

    context "when a class instance" do
      it "should initialize a new BossQueue::Job object, save and call enqueue on it" do
        BossQueue.environment = 'test'
        BossQueue.failure_action = 'retry'
        BossQueue::Job.any_instance.should_receive(:kind=).with('TestClass#test_instance_method')
        BossQueue::Job.any_instance.should_receive(:queue_name=).with('test_boss_queue')
        BossQueue::Job.any_instance.should_receive(:failure_action=).with('retry')
        BossQueue::Job.any_instance.should_receive(:model_class_name=).with('TestClass')
        BossQueue::Job.any_instance.should_receive(:model_id=).with('xyz')
        BossQueue::Job.any_instance.should_receive(:job_method=).with('test_instance_method')
        BossQueue::Job.any_instance.should_receive(:job_arguments=).with(@argument_json)
        BossQueue::Job.any_instance.should_receive(:save)
        BossQueue::Job.any_instance.should_receive(:enqueue)
        BossQueue.enqueue(TestClass.new, :test_instance_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
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
        BossQueue.environment = 'test'
        BossQueue.failure_action = 'retry'
        BossQueue::Job.any_instance.should_receive(:kind=).with('TestClass@test_class_method')
        BossQueue::Job.any_instance.should_receive(:queue_name=).with('test_boss_queue')
        BossQueue::Job.any_instance.should_receive(:failure_action=).with('retry')
        BossQueue::Job.any_instance.should_receive(:model_class_name=).with('TestClass')
        BossQueue::Job.any_instance.should_not_receive(:model_id=)
        BossQueue::Job.any_instance.should_receive(:job_method=).with('test_class_method')
        BossQueue::Job.any_instance.should_receive(:job_arguments=).with(@argument_json)
        BossQueue::Job.any_instance.should_receive(:save)
        BossQueue::Job.any_instance.should_receive(:enqueue_with_delay).with(60)
        BossQueue.enqueue_with_delay(60, TestClass, :test_class_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
      end
    end

    context "when a class instance" do
      it "should initialize a new BossQueue::Job object, save and call enqueue on it" do
        BossQueue.environment = 'test'
        BossQueue.failure_action = 'retry'
        BossQueue::Job.any_instance.should_receive(:kind=).with('TestClass#test_instance_method')
        BossQueue::Job.any_instance.should_receive(:queue_name=).with('test_boss_queue')
        BossQueue::Job.any_instance.should_receive(:failure_action=).with('retry')
        BossQueue::Job.any_instance.should_receive(:model_class_name=).with('TestClass')
        BossQueue::Job.any_instance.should_receive(:model_id=).with('xyz')
        BossQueue::Job.any_instance.should_receive(:job_method=).with('test_instance_method')
        BossQueue::Job.any_instance.should_receive(:job_arguments=).with(@argument_json)
        BossQueue::Job.any_instance.should_receive(:save)
        BossQueue::Job.any_instance.should_receive(:enqueue_with_delay).with(60)
        BossQueue.enqueue_with_delay(60, TestClass.new, :test_instance_method, 'a', 'b', { 'c' => 2, 'd' => 1 })
      end
    end

  end

  describe "#work" do
    before(:each) do
      @queue = double('queue')
      AWS::SQS.stub_chain(:new, :queues, :[]).and_return(@queue)

      @sqs_message = double('message')
      @sqs_message.stub(:body).and_return('ijk')
      @queue.stub(:receive_message).and_yield(@sqs_message)

      @job = double('job')
      @job.stub(:work)
      BossQueue::Job.stub(:find_by_id).and_return(@job)
    end

    it "should dequeue from SQS" do
      @queue.should_receive(:receive_message).and_yield(@sqs_message)
      BossQueue.work
    end

    context "when something is dequeued from SQS" do
      it "should use the dequeued id to retrieve a BossQueue::Job object" do
        @queue.should_receive(:receive_message).and_yield(@sqs_message)
        BossQueue::Job.should_receive(:find_by_id).with('ijk').and_return(@job)
        BossQueue.work
      end

      it "should call work on the BossQueue::Job object" do
        @job.should_receive(:work)
        BossQueue.work
      end
    end
  end

end
