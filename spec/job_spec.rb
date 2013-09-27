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
    context "when model_id is not nil" do
      it "should use #find on the model class to instantiate an object to work on" do
        pending
      end

      it "should pass the job arguments to the job method" do
        pending
      end
    end

    context "when model_id is nil" do
      it "should call the job method on the class" do
        pending
      end

      it "should pass the job arguments to the job method" do
        pending
      end
    end

    context "when the job method raises an exception" do

    end
  end

  describe "#succeed" do
    it "should call delete" do
      pending
    end
  end

  describe "#enqueue" do
    it "should enqueue id into the SQS queue" do
      pending
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

  describe "#delete_message" do
    it "should" do
      pending
    end
  end

  describe "#delete" do
    it "should call #delete_message" do
      pending
    end
  end

end
