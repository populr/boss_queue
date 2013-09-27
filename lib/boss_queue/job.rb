require 'json'

class BossQueue

  class Job < AWS::Record::HashModel
    attr_accessor :queue_name

    string_attr :kind # an index based model_class_name, job_method
    boolean_attr :failed

    string_attr :model_class_name
    string_attr :model_id
    string_attr :job_method
    string_attr :job_arguments

    integer_attr :failed_attempts
    string_attr :failure_action
    string_attr :exception_name
    string_attr :exception_message
    string_attr :stacktrace

    timestamps

    def enqueue
      queue = AWS::SQS.new.queues[queue_name]
      queue.send_message(id.to_s)
    end

    def enqueue_with_delay(delay)
      queue = AWS::SQS.new.queues[queue_name]
      queue.send_message(id.to_s, :delay_seconds => delay)
    end

    def work
      begin
        klass = constantize(model_class_name)
        if model_id
          target = klass.find(model_id)
        else
          target = klass
        end
        args = JSON.parse(job_arguments)
        target.send(job_method, *args)
        destroy
      rescue StandardError => err
        fail(err)
      end
    end

    def fail(err)
      self.failed_attempts ||= 0
      self.failed_attempts += 1
      self.exception_name = err.class.to_s
      self.exception_message = err.message
      self.stacktrace = err.backtrace[0, 7].join("\n")

      if failure_action == 'retry' && retry_delay
        enqueue_with_delay(retry_delay)
      else
        self.failed = true
      end

      self.save!
    end

    def retry_delay
      return nil if failed_attempts.nil? || failed_attempts > 4
      60 * 2**(failed_attempts - 1)
    end

    # from ActiveSupport source: http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-constantize
    def constantize(camel_cased_word) # :nodoc:
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      names.inject(Object) do |constant, name|
        if constant == Object
          constant.const_get(name)
        else
          candidate = constant.const_get(name)
          next candidate if constant.const_defined?(name, false)
          next candidate unless Object.const_defined?(name)

          # Go down the ancestors to check it it's owned
          # directly before we reach Object or the end of ancestors.
          constant = constant.ancestors.inject do |const, ancestor|
            break const    if ancestor == Object
            break ancestor if ancestor.const_defined?(name, false)
            const
          end

          # owner is in Object, so raise
          constant.const_get(name, false)
        end
      end
    end

  end

end
