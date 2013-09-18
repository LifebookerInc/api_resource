require 'api_resource/typecasters/boolean_typecaster'
require 'api_resource/typecasters/date_typecaster'
require 'api_resource/typecasters/float_typecaster'
require 'api_resource/typecasters/integer_typecaster'
require 'api_resource/typecasters/string_typecaster'
require 'api_resource/typecasters/time_typecaster'
require 'api_resource/typecasters/array_typecaster'

# Apparently need to require the active_support class_attribute
require 'active_support/core_ext/class/attribute'


module ApiResource

  module Typecast

    extend ActiveSupport::Concern

    included do
      class_attribute :typecasters

      self.typecasters = self.default_typecasters
    end

    module ClassMethods
      # Takes a typecaster name (converted to all lowercase) and
      # either a klass (as a constant) or a block to define an anonymous module
      # and registers a new typecaster that defines the method typecast!(value)
      def register_typecaster(name, klass = nil, &block)
        caster = name.to_s.downcase.to_sym

        if self.typecasters[caster]
          raise ArgumentError, "Typecaster #{name} already exists"
        end

        if block_given?
          unless klass.nil?
            raise ArgumentError, "Cannot declare a typecaster with a class and a block"
          end

          klass = Module.new(&block)
        elsif klass.nil?
          raise ArgumentError, "Must specify a typecaster with either a class or a block"
        end

        unless klass.respond_to?(:from_api) && klass.respond_to?(:to_api)
          raise ArgumentError, "Typecaster must respond to from_api and to_api"
        end

        self.typecasters[caster] = klass

      end

      # Redefines a typecaster (or defines it if it doesn't exist)
      # basically just delegates to register_typecaster
      def redefine_typecaster!(name, klass = nil, &block)
        caster = name.to_s.downcase.to_sym
        # clone the original typecasters hash so that the override
        # only applies to this class and subclasses
        self.typecasters = self.typecasters.clone
        self.typecasters.delete(caster)
        self.register_typecaster(name, klass, &block)
      end

      def default_typecasters
        @default_typecasters ||= {
          :boolean => BooleanTypecaster,
          :bool => BooleanTypecaster,
          :date => DateTypecaster,
          :decimal => FloatTypecaster,
          :float => FloatTypecaster,
          :integer => IntegerTypecaster,
          :int => IntegerTypecaster,
          :string => StringTypecaster,
          :text => StringTypecaster,
          :time => TimeTypecaster,
          :datetime => TimeTypecaster,
          :array => ArrayTypecaster,
        }
      end

    end

  end

end
