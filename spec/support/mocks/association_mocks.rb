include ApiResource

Mocks.define do
  
  endpoint('/single_object_association') do
    get(HashDealer.roll(:test_association_resource), :params => {})
    get(HashDealer.roll(:active_test_association_resource), :params => {:active => true})
    get(HashDealer.roll(:active_birthday_test_association_resource), :params => {:active => true, :birthday => true})
  end

  endpoint('/multi_object_association') do
    get((0..4).to_a.collect{HashDealer.roll(:test_association_resource)}, :params => {})
    get((0..4).to_a.collect{HashDealer.roll(:active_test_association_resource)}, :params => {:active => true})
    get((0..4).to_a.collect{HashDealer.roll(:active_test_association_resource)}, :params => {:active => false})
    get((0..4).to_a.collect{HashDealer.roll(:active_birthday_test_association_resource)}, :params => {:active => true, :birthday => true})
  end

  endpoint("/has_one_objects/new") do
    get({})
  end
  
  endpoint("/has_many_objects/new") do
    get({})
  end
  
  endpoint("/belongs_to_objects/new") do
    get({})
  end
  
  endpoint("/test_associations/new") do
    get({})
  end
  
  endpoint("/inner_classes/new") do
    get({})
  end
  
  endpoint("/childern/new") do
    get({})
  end
  
end