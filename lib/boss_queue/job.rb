class BossQueue

  class Job < AWS::Record::HashModel
    attr_accessor :table_name

    string_attr :kind # an index based model_class_name, job_method
    boolean_attr :failed

    string_attr :queue_name
    string_attr :queue_message_id
    integer_attr :failed_attempts
    string_attr :failure_action
    string_attr :exception_name
    string_attr :exception_message
    string_attr :stacktrace
    string_attr :model_class_name
    string_attr :model_id
    string_attr :job_method
    string_attr :job_arguments

    timestamps

  end

end
