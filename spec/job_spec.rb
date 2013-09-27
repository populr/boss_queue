require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "BossQueue::Job" do

  it "should respond to table_name" do
    BossQueue::Job.new.should respond_to(:table_name)
  end

  it "should respond to table_name=" do
    BossQueue::Job.new.should respond_to(:table_name=)
  end


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


  it "should respond to queue_name" do
    BossQueue::Job.new.should respond_to(:queue_name)
  end

  it "should respond to queue_name=" do
    BossQueue::Job.new.should respond_to(:queue_name=)
  end


  it "should respond to queue_message_id" do
    BossQueue::Job.new.should respond_to(:queue_message_id)
  end

  it "should respond to queue_message_id=" do
    BossQueue::Job.new.should respond_to(:queue_message_id=)
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
      AWS::SQS.stub_chain(:new, :queues, :[]).and_return(queue)
      queue.should_receive(:send_message).with('ijk', :delay_seconds => 60)
      job = BossQueue::Job.new
      job.id = 'ijk'
      job.enqueue_with_delay(60)
    end
  end

  describe "#fail" do
    context "when retry_delay returns a number" do
      it "should re-enqueue with that delay" do
        pending
      end

      it "should increment failure count" do
        pending
      end

      it "should store the exception and stacktrace in the BossQueue::Job object" do
        pending
      end
    end

    context "when retry_delay returns nil" do
      it "should not re-enqueue" do
        pending
      end

      it "should call delete_message" do
        pending
      end
    end
  end

end
