module ApiResource

	module Conditions

		class AbstractCondition

			include Enumerable

			attr_reader :conditions, :klass, :included_objects, :internal_object, :association,
									:remote_path
			
			# TODO: add the other load forcing methods here for collections
			delegate :[], :[]=, :<<, :first, :second, :last, :blank?, :nil?, :include?, :push, :pop,
							 :+, :concat, :flatten, :flatten!, :compact, :compact!, :empty?, :fetch, :map,
							 :reject, :reject!, :reverse, :select, :select!, :size, :sort, :sort!, :uniq, :uniq!,
							 :to_a, :sample, :slice, :slice!, :count, :present?, :to => :internal_object

			# need to figure out what to do with args in the subclass,
			# parent is the set of scopes we have right now
			def initialize(args, klass)
				@klass = klass

				@conditions = args.with_indifferent_access

				@klass.load_resource_definition
			end

			def each(&block)
				self.internal_object.each(&block)
			end

			def blank_conditions?
				self.conditions.blank?
			end

			def eager_load?
				self.included_objects.present?
			end 

			def included_objects
				Array.wrap(@included_objects)
			end

			def to_query
				CGI.unescape(to_query_safe_hash(self.to_hash).to_query)
			end

			def to_hash
				self.conditions
			end

			def internal_object
				return @internal_object if @loaded
				@internal_object = self.instantiate_finder.load
				@loaded = true
				@internal_object
			end

			def all(*args)
				if args.blank?
					self.internal_object
				else
					self.find(*([:all] + args))
				end
			end

			# implement find that accepts an optional
			# condition object 
			def find(*args)
				self.klass.find(*(args + [self]))
			end

			# TODO: review the hierarchy that makes this necessary
			# consider changing it to alias method
			def load
				self.internal_object
			end

			def loaded?
				@loaded == true
			end

			def reload
				if instance_variable_defined?(:@internal_object)
					remove_instance_variable(:@internal_object)
				end
				@loaded = false
			end

			def method_missing(sym, *args, &block)
				result = @klass.send(sym, *args, &block)

				if result.is_a?(ApiResource::Conditions::AbstractCondition)
					return self.dup.merge!(result)
				else
					return result
				end
			end

			def expires_in(time)
				ApiResource::Decorators::CachingDecorator.new(self, time)
			end

			# TODO: Remove the bang, this doesn't modify anything
			def merge!(cond)
				@included_objects = (@included_objects || []).concat(cond.included_objects || []).uniq
				@conditions = @conditions.merge(cond.to_hash)
				@association = cond.association || self.association
				@remote_path = self.remote_path ? self.remote_path : cond.remote_path
				return self
			end

			protected

			def instantiate_finder
				ApiResource::Finders::ResourceFinder.new(self.klass, self)
			end

			def to_query_safe_hash(hash)
				hash.each_pair do |k,v|
					hash[k] = to_query_safe_hash(v) if v.is_a?(Hash)
					hash[k] = true if v == {}
				end
				return hash
			end

		end

	end

end