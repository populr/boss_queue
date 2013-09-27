require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "BossQueue::Job" do

  it "should respond to id" do
    BossQueue::Job.new.should respond_to(:id)
  end

  it "should respond to id=" do
    BossQueue::Job.new.should respond_to(:id=)
  end


  it "should respond to failed" do
    BossQueue::Job.new.should respond_to(:failed)
  end

  it "should respond to failed=" do
    BossQueue::Job.new.should respond_to(:failed=)
  end

  describe "#failed" do
    it "should default to false" do
      BossQueue::Job.new.failed.should be_false
    end
  end

  it "should respond to queue_name" do
    BossQueue::Job.new.should respond_to(:queue_name)
  end

  it "should respond to queue_name=" do
    BossQueue::Job.new.should respond_to(:queue_name=)
  end

  it "should respond to failed_attempts" do
    BossQueue::Job.new.should respond_to(:failed_attempts)
  end

  it "should respond to failed_attempts=" do
    BossQueue::Job.new.should respond_to(:failed_attempts=)
  end


  it "should respond to failure_action" do
    BossQueue::Job.new.should respond_to(:failure_action)
  end

  it "should respond to failure_action=" do
    BossQueue::Job.new.should respond_to(:failure_action=)
  end


  it "should respond to exception_name" do
    BossQueue::Job.new.should respond_to(:exception_name)
  end

  it "should respond to exception_name=" do
    BossQueue::Job.new.should respond_to(:exception_name=)
  end


  it "should respond to exception_message" do
    BossQueue::Job.new.should respond_to(:exception_message)
  end

  it "should respond to exception_message=" do
    BossQueue::Job.new.should respond_to(:exception_message=)
  end


  it "should respond to stacktrace" do
    BossQueue::Job.new.should respond_to(:stacktrace)
  end

  it "should respond to stacktrace=" do
    BossQueue::Job.new.should respond_to(:stacktrace=)
  end


  it "should respond to model_class_name" do
    BossQueue::Job.new.should respond_to(:model_class_name)
  end

  it "should respond to model_class_name=" do
    BossQueue::Job.new.should respond_to(:model_class_name=)
  end


  it "should respond to model_id" do
    BossQueue::Job.new.should respond_to(:model_id)
  end

  it "should respond to model_id=" do
    BossQueue::Job.new.should respond_to(:model_id=)
  end


  it "should respond to job_method" do
    BossQueue::Job.new.should respond_to(:job_method)
  end

  it "should respond to job_method=" do
    BossQueue::Job.new.should respond_to(:job_method=)
  end


  it "should respond to job_arguments" do
    BossQueue::Job.new.should respond_to(:job_arguments)
  end

  it "should respond to job_arguments=" do
    BossQueue::Job.new.should respond_to(:job_arguments=)
  end


  describe "#work" do
    before(:each) do
      @job = BossQueue::Job.new
      @job.stub(:destroy)
      @job.model_class_name = 'TestClass'
      @job.model_id = 'xyz'
      @job.job_method = 'test_instance_method'
      @arguments = ['a', 'b', { 'c' => 2, 'd' => 1 }]
      @argument_json = JSON.generate(@arguments)
      @job.job_arguments = @argument_json
      @instance_to_work_on = double('instance_to_work_on')
      @instance_to_work_on.stub(:test_instance_method)
      TestClass.stub(:find).and_return(@instance_to_work_on)
    end


    context "when model_id is not nil" do
      it "should use #find on the model class to instantiate an object to work on" do
        TestClass.should_receive(:find).with('xyz').and_return(@instance_to_work_on)
        @job.work
      end

      it "should pass the job arguments to the job method" do
        @instance_to_work_on.should_receive(:test_instance_method).with('a', 'b', { 'c' => 2, 'd' => 1 })
        @job.work
      end
    end

    context "when model_id is nil" do
      before(:each) do
        @job = BossQueue::Job.new
        @job.stub(:destroy)
        @job.model_class_name = 'TestClass'
        @job.job_method = 'test_class_method'
        @arguments = ['a', 'b', { 'c' => 2, 'd' => 1 }]
        @argument_json = JSON.generate(@arguments)
        @job.job_arguments = @argument_json
      end

      it "should pass the job arguments to the job method on the class" do
        TestClass.should_receive(:test_class_method).with('a', 'b', { 'c' => 2, 'd' => 1 })
        @job.work
      end
    end

    context "when the job method doesn't raise an exception" do
      it "should call destroy" do
        @job.should_receive(:destroy)
        @job.work
      end
    end

    context "when the job method raises an exception" do
      before(:each) do
        @instance_to_work_on.stub(:test_instance_method).and_raise(StandardError.new)
        @job.stub(:fail)
      end

      it "should call fail" do
        @job.should_receive(:fail)
        @job.work
      end

      it "should not call destroy" do
        @job.should_not_receive(:destroy)
        @job.work
      end

      it "should not raise an exception" do
        lambda {
          @job.work
        }.should_not raise_error
      end
    end

  end

  describe "#enqueue" do
    it "should enqueue id into the SQS queue" do
      queue = double('queue')
      AWS::SQS.stub_chain(:new, :queues, :url_for).and_return('queue_url')
      AWS::SQS.stub_chain(:new, :queues, :[]).and_return(queue)
      queue.should_receive(:send_message).with('ijk')
      job = BossQueue::Job.new
      job.id = 'ijk'
      job.enqueue
    end
  end

  describe "#enqueue_with_delay" do
    it "should enqueue id into the SQS queue with a delay" do
      queue = double('queue')
      AWS::SQS.stub_chain(:new, :queues, :url_for).and_return('queue_url')
      AWS::SQS.stub_chain(:new, :queues, :[]).and_return(queue)
      queue.should_receive(:send_message).with('ijk', :delay_seconds => 60)
      job = BossQueue::Job.new
      job.id = 'ijk'
      job.enqueue_with_delay(60)
    end

    it "should limit the delay to 15 minutes" do
      queue = double('queue')
      AWS::SQS.stub_chain(:new, :queues, :url_for).and_return('queue_url')
      AWS::SQS.stub_chain(:new, :queues, :[]).and_return(queue)
      queue.should_receive(:send_message).with('ijk', :delay_seconds => 900)
      job = BossQueue::Job.new
      job.id = 'ijk'
      job.enqueue_with_delay(10000)
    end

    it "should set a negative delay to 0" do
      queue = double('queue')
      AWS::SQS.stub_chain(:new, :queues, :url_for).and_return('queue_url')
      AWS::SQS.stub_chain(:new, :queues, :[]).and_return(queue)
      queue.should_receive(:send_message).with('ijk', :delay_seconds => 0)
      job = BossQueue::Job.new
      job.id = 'ijk'
      job.enqueue_with_delay(-60)
    end
  end

  describe "#retry_delay" do
    before(:each) do
      @job = BossQueue::Job.new
    end

    context "when failed_attempts is nil" do
      it "should be nil" do
        @job.retry_delay.should == nil
      end
    end

    context "when failed_attempts is 1" do
      it "should be 60" do
        @job.failed_attempts = 1
        @job.retry_delay.should == 60
      end
    end

    context "when failed_attempts is 2" do
      it "should be 120" do
        @job.failed_attempts = 2
        @job.retry_delay.should == 120
      end
    end

    context "when failed_attempts is 3" do
      it "should be 240" do
        @job.failed_attempts = 3
        @job.retry_delay.should == 240
      end
    end

    context "when failed_attempts is 4" do
      it "should be 480" do
        @job.failed_attempts = 4
        @job.retry_delay.should == 480
      end
    end

    context "when failed_attempts greater than 4" do
      it "should be nil ((60 + 120 + 240 + 480) == 900 (15 minutes), the maximum delay supported by SQS)" do
        @job.failed_attempts = 5
        @job.retry_delay.should be_nil
      end
    end
  end

  describe "#fail" do
    before(:each) do
      @job = BossQueue::Job.new
      @job.stub(:retry_delay).and_return(nil)
      @job.stub(:save!)
      @job.stub(:enqueue_with_delay)
      @err
      begin
        raise StandardError.new('hello world')
      rescue StandardError => err
        @err = err
      end
    end

    context "when failed_attempts is a number" do
      it "should increment failed_attempts" do
        @job.failed_attempts = 1
        @job.fail(@err)
        @job.failed_attempts.should == 2
      end
    end

    it "should store the exception, message, and the first 7 lines of the stacktrace in the BossQueue::Job object" do
      @job.fail(@err)
      @job.exception_name.should == @err.class.to_s
      @job.exception_message.should == @err.message
      @job.stacktrace.should == @err.backtrace[0, 7].join("\n")
    end

    it "should call save!" do
      @job.should_receive(:save!)
      @job.fail(@err)
    end

    context "when failure_action is 'retry'" do
      before(:each) do
        @job.failure_action = 'retry'
      end

      context "when retry_delay returns a number" do
        it "should re-enqueue with that delay" do
          @job.stub(:retry_delay).and_return(60)
          @job.should_receive(:enqueue_with_delay).with(60)
          @job.fail(@err)
        end

        context "when failed_attempts is nil" do
          it "should set failed_attempts to 1" do
            @job.fail(@err)
            @job.failed_attempts.should == 1
          end
        end
      end

      context "when retry_delay returns nil" do
        it "should not re-enqueue" do
          @job.should_not_receive(:enqueue)
          @job.should_not_receive(:enqueue_with_delay)
          @job.fail(@err)
        end

        it "should set failed to true" do
          @job.fail(@err)
          @job.failed.should be_true
        end
      end
    end

    context "when failure_action is not 'retry'" do
      it "should not re-enqueue" do
        @job.should_not_receive(:enqueue)
        @job.should_not_receive(:enqueue_with_delay)
        @job.fail(@err)
      end
    end
  end

end
