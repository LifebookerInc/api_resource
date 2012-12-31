
module ApiResource

	module Finders

		class AbstractFinder

			attr_accessor :condition, :klass
			attr_reader :found, :internal_object

			# TODO: Make this list longer since there are for sure more methods to delegate
			delegate :to_s, :inspect, :reload, :present?, :blank?, :size, :to => :internal_object

			def initialize(klass, condition)
				@klass = klass
				@condition = condition
				@found = false
				@internal_object = nil
			end

			def find
				raise NotImplementedError("Must be defined in a subclass")
			end

			def internal_object
				# If we've already tried to load return what we've got
				if instance_variable_defined?(:@internal_object)
					return instance_variable_get(:@internal_object)
				end
				# If we haven't tried to load then just call find
				self.find
			end

			# proxy unknown methods to the internal_object
			def method_missing(method, *args, &block)
				self.internal_object.send(method, *args, &block)
			end

			protected

			# This returns a hash of class_names (given by the condition object)
			# to an array of objects
			def load_includes(id_hash)
				# Quit early if the condition is not eager
				return {} unless self.condition.eager_load?
				# Otherwise go through each class_name that is included, and load the ids
				# given in id_hash, at this point we know all these associations have their
				# proper names

				hsh = HashWithIndifferentAccess.new
				id_hash = HashWithIndifferentAccess.new(id_hash)
				# load each individually
				self.condition.included_objects.inject(hsh) do |accum, assoc|
					accum[assoc.to_sym] = self.klass.association_class(assoc).find(
						:all, 
						:id => id_hash[assoc])
				end

				hsh
			end

			def apply_includes(objects, includes)
				Array.wrap(objects).each do |obj|
					includes.each_pair do |assoc, vals|
						ids_to_keep = obj.send(obj.class.association_foreign_key_field(assoc))
						to_keep = vals.select{|elm| ids_to_keep.include?(elm.id)}
						obj.send("#{assoc}=", to_keep)
					end
				end
			end

			def build_load_path
				raise "This is not finding an association" unless self.condition.remote_path

        path = self.condition.remote_path
        # add a format if it doesn't exist and there is no query string yet
        path += ".#{self.klass.format.extension}" unless path =~ /\./ || path =~/\?/
        # add the query string, allowing for other user-provided options in the remote_path if we have options
        unless self.condition.blank_conditions?
          path += (path =~ /\?/ ? "&" : "?") + self.condition.to_query 
        end
        path
			end

		end

	end

end