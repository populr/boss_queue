require 'json'

class BossQueue

  class Job < AWS::Record::HashModel
    attr_accessor :queue_name

    boolean_attr :failed

    string_attr :model_class_name
    string_attr :model_id
    string_attr :callback
    string_attr :args

    integer_attr :failed_attempts
    string_attr :failure_action
    string_attr :failure_callback
    string_attr :exception_name
    string_attr :exception_message
    string_attr :stacktrace

    timestamps

    class << self
      # We need consistent reads, so override @find_by_id
      #
      # @param [String] id The id of the record to load.
      # @param [Hash] options
      # @option options [String] :shard Specifies what shard (i.e. table)
      #   should be searched.
      # @raise [RecordNotFound] Raises a record not found exception if there
      #   was no data found for the given id.
      # @return [Record::HashModel] Returns the record with the given id.
      def find_by_id id, options = {}

        table = dynamo_db_table(options[:shard])

        data = table.items[id].attributes.to_h(:consistent_read => options[:consistent_read])

        raise RecordNotFound, "no data found for id: #{id}" if data.empty?

        obj = self.new(:shard => table)
        obj.send(:hydrate, id, data)
        obj

      end
      alias_method :[], :find_by_id
    end



    def enqueue
      sqs_queue.send_message(id.to_s)
    end

    def enqueue_with_delay(delay)
      sqs_queue.send_message(id.to_s, :delay_seconds => [900, [0, delay].max].min)
    end

    def work
      begin
        target.send(callback, *arguments)
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
        self.save!

      elsif failure_action == 'callback' &&
            failure_callback

        delete_me = target.send(failure_callback, err, *arguments) rescue nil
        if delete_me
          destroy
        else
          self.failed = true
          self.save!
        end

      else
        self.failed = true
        self.save!
      end
    end

    def retry_delay
      return nil if failed_attempts.nil? || failed_attempts > 4
      60 * 2**(failed_attempts - 1)
    end

    def sqs_queue=(queue_obj) # :nodoc:
      @sqs_queue = queue_obj
    end

    private

    def arguments
      JSON.parse(args)
    end

    def target
      klass = constantize(model_class_name)
      if model_id
        klass.find(model_id)
      else
        klass
      end
    end

    def sqs_queue
      @sqs_queue ||= AWS::SQS.new.queues[AWS::SQS.new.queues.url_for(queue_name)]
    end

    # from ActiveSupport source: http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-constantize
    def constantize(camel_cased_word)
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
