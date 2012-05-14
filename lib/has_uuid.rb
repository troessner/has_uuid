require 'uuidtools'

module ActiveRecord
  module Acts
    # has_uuid adds a UUID to your models. See the README for details.
    module HasUuid
      GENERATORS = [:random, :timestamp]
      DEFAULT_OPTIONS = {:auto => true, :generator => :random, :column => :uuid}

      # Class Macro which actually lets models use has_uuid
      # @param options:
      # * column:   The column in which to store the UUID (default: uuid).
      # * auto:     Assign a UUID on create (default: true).
      # * generator The UUID generator. Possible values are `random` default) and `timestamp`.
      def has_uuid(options = {})
        options.reverse_merge! DEFAULT_OPTIONS
        raise ArgumentError, "Invalid UUID generator #{options[:generator]}" unless GENERATORS.include?(options[:generator])

        class_eval do
          include InstanceMethods

          if options[:auto]
            before_validation(:on => :create) { assign_uuid }
            before_save(:on => :create) { assign_uuid }
          end

          class_attribute :uuid_column
          self.uuid_column = options[:column]

          class_attribute :uuid_generator
          self.uuid_generator = options[:generator]
        end
      end

      def generate_uuid
        UUIDTools::UUID.send("#{uuid_generator}_create").to_s
      end

      module InstanceMethods
        def assign_uuid(options = {})
          return if uuid_valid? unless options[:force]

          uuid = UUIDTools::UUID.send("#{uuid_generator}_create").to_s
          send("#{uuid_column}=", uuid)
        end

        def assign_uuid!
          assign_uuid(:force => true)
          save!
        end

        def uuid_valid?
          uuid = send(uuid_column)
          return false if uuid.blank?
          begin
            UUIDTools::UUID.parse(uuid).kind_of?(UUIDTools::UUID)
          rescue ArgumentError, TypeError
            false
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  extend ActiveRecord::Acts::HasUuid
end
