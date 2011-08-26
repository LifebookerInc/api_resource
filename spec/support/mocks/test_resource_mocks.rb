include ApiResource

Mocks.define do
  
  endpoint("/test_resources/new") do
    get(HashDealer.roll(:new_test_object))
  end
  
  endpoint("/test_resources") do
    post(HashDealer.roll(:test_resource).merge(:id => 1), :params => {:test_resource => HashDealer.roll(:test_resource).matcher})
    get((0..4).to_a.collect{HashDealer.roll(:test_resource)})
    get((0..4).to_a.collect{HashDealer.roll(:test_resource)}, :params => {:active => true})
  end
  
  endpoint("/test_resources/:id") do
    get(HashDealer.roll(:test_resource)) do |params|
      self.merge(params)
    end
    delete({})
    put({}, :params => {:test_resource => HashDealer.roll(:test_resource).matcher})
  end
  
end