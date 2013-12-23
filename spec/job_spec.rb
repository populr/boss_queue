require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "BossQueue::Job" do

  it "should respond to id" do
    BossQueue::Job.new.should respond_to(:id)
  end

  it "should respond to id=" do
    BossQueue::Job.new.should respond_to(:id=)
  end



  it "should respond to target_missing?" do
    BossQueue::Job.new.should respond_to(:target_missing?)
  end

  it "should respond to target_missing=" do
    BossQueue::Job.new.should respond_to(:target_missing=)
  end

  describe "#target_missing?" do
    it "should default to false" do
      BossQueue::Job.new.target_missing?.should be_false
    end
  end


  it "should respond to delete_if_target_missing?" do
    BossQueue::Job.new.should respond_to(:delete_if_target_missing?)
  end

  it "should respond to delete_if_target_missing=" do
    BossQueue::Job.new.should respond_to(:delete_if_target_missing=)
  end

  describe "#delete_if_target_missing?" do
    it "should default to false" do
      BossQueue::Job.new.delete_if_target_missing?.should be_false
    end
  end


  it "should respond to failed?" do
    BossQueue::Job.new.should respond_to(:failed?)
  end

  it "should respond to failed=" do
    BossQueue::Job.new.should respond_to(:failed=)
  end

  describe "#failed?" do
    it "should default to false" do
      BossQueue::Job.new.failed?.should be_false
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


  it "should respond to callback" do
    BossQueue::Job.new.should respond_to(:callback)
  end

  it "should respond to callback=" do
    BossQueue::Job.new.should respond_to(:callback=)
  end


  it "should respond to args" do
    BossQueue::Job.new.should respond_to(:args)
  end

  it "should respond to args=" do
    BossQueue::Job.new.should respond_to(:args=)
  end


  describe "#work" do
    before(:each) do
      @job = BossQueue::Job.new
      @job.stub(:destroy)
      @job.model_class_name = 'TestClass'
      @job.model_id = 'xyz'
      @job.callback = 'test_instance_method'
      @arguments = ['a', 'b', { 'c' => 2, 'd' => 1 }]
      @argument_json = JSON.generate(@arguments)
      @job.args = @argument_json
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
        @job.callback = 'test_class_method'
        @arguments = ['a', 'b', { 'c' => 2, 'd' => 1 }]
        @argument_json = JSON.generate(@arguments)
        @job.args = @argument_json
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
      sqs_queue = double('queue')
      sqs_queues = double('queues')
      sqs_queues.stub(:[]).and_return(sqs_queue)
      BossQueue.stub(:sqs_queues).and_return(sqs_queues)
      BossQueue.stub(:sqs_queue_url).and_return('queue_url')

      sqs_queue.should_receive(:send_message).with('ijk')
      job = BossQueue::Job.new
      job.id = 'ijk'
      job.enqueue
    end
  end

  describe "#enqueue_with_delay" do
    it "should enqueue id into the SQS queue with a delay" do
      sqs_queue = double('queue')
      sqs_queues = double('queues')
      sqs_queues.stub(:[]).and_return(sqs_queue)
      BossQueue.stub(:sqs_queues).and_return(sqs_queues)
      BossQueue.stub(:sqs_queue_url).and_return('queue_url')


      sqs_queue.should_receive(:send_message).with('ijk', :delay_seconds => 60)
      job = BossQueue::Job.new
      job.id = 'ijk'
      job.enqueue_with_delay(60)
    end

    it "should limit the delay to 15 minutes" do
      sqs_queue = double('queue')
      sqs_queues = double('queues')
      sqs_queues.stub(:[]).and_return(sqs_queue)
      BossQueue.stub(:sqs_queues).and_return(sqs_queues)
      BossQueue.stub(:sqs_queue_url).and_return('queue_url')


      sqs_queue.should_receive(:send_message).with('ijk', :delay_seconds => 900)
      job = BossQueue::Job.new
      job.id = 'ijk'
      job.enqueue_with_delay(10000)
    end

    it "should set a negative delay to 0" do
      sqs_queue = double('queue')
      sqs_queues = double('queues')
      sqs_queues.stub(:[]).and_return(sqs_queue)
      BossQueue.stub(:sqs_queues).and_return(sqs_queues)
      BossQueue.stub(:sqs_queue_url).and_return('queue_url')

      sqs_queue.should_receive(:send_message).with('ijk', :delay_seconds => 0)
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
      @instance_to_work_on = double('instance_to_work_on')
      @instance_to_work_on.stub(:test_instance_method)
      @instance_to_work_on.stub(:failure).and_return(false)
      TestClass.stub(:find).and_return(@instance_to_work_on)

      @job = BossQueue::Job.new
      @job.stub(:retry_delay).and_return(nil)
      @job.stub(:save!)
      @job.stub(:enqueue_with_delay)

      @job.stub(:destroy)
      @job.model_class_name = 'TestClass'
      @job.model_id = 'xyz'
      @job.callback = 'test_instance_method'
      @arguments = ['a', 'b', { 'c' => 2, 'd' => 1 }]
      @argument_json = JSON.generate(@arguments)
      @job.args = @argument_json

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
      @job.stacktrace.should == @err.backtrace[0, 15].join("\n")
    end

    it "should call save!" do
      @job.should_receive(:save!)
      @job.fail(@err)
    end





    context "when delete_if_target_missing is true and the target cannot be found" do
      it "should destroy the record" do
        @job.failure_action = 'callback'
        @job.failure_callback = 'failure'
        @job.delete_if_target_missing = true
        TestClass.stub(:find).and_raise('not found')

        @job.should_receive(:destroy)
        @job.fail(@err)
      end
    end




    context "when delete_if_target_missing is false and the target cannot be found" do
      before(:each) do
        @job.failure_action = 'callback'
        @job.failure_callback = 'failure'
        TestClass.stub(:find).and_raise('not found')
      end

      it "should set target_missing on the job" do
        @job.fail(@err)
        @job.target_missing.should be_true
      end

      it "should not destroy the record" do
        @job.should_not_receive(:destroy)
        @job.fail(@err)
      end
    end




    context "when failure_action is 'callback'" do
      before(:each) do
        @job.failure_action = 'callback'
        @job.failure_callback = 'failure'
      end

      it "should call the failure_callback method with the exception and the callback arguments" do
        @instance_to_work_on.should_receive(:failure).with(instance_of(StandardError), 'a', 'b', { 'c' => 2, 'd' => 1 })
        @job.fail(@err)
      end

      context "when the failure_callback method returns truthy" do
        it "should delete the job" do
          @job.should_receive(:destroy)
          @instance_to_work_on.stub(:failure).and_return(true)
          @job.fail(@err)
        end
      end

      context "when the failure_callback method returns falsey" do
        it "should mark the job as failed" do
          @job.should_not_receive(:destroy)
          @instance_to_work_on.stub(:failure).and_return(false)
          @job.fail(@err)
          @job.failed.should be_true
        end
      end

      context "when finding the target to call back raises an exception" do
        it "should not raise an exception" do
          @job.stub(:target).and_raise('object not found')
          lambda {
            @job.fail(@err)
          }.should_not raise_error
        end
      end
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
