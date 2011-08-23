class Array
  
  def symbolize_array
    self.collect{|item| item.to_s.to_sym}
  end
  
end