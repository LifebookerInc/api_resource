module ApiResource

  # Simple class that has no instance methods
  # to use as a superclass for proxy objects
  class BlankSlate
    # Remove all instance methods
    instance_methods.each do |m|
      undef_method(m) unless (m.match(/^__/))
    end

  end

end