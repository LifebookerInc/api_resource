include ApiResource

Mocks.define do
  
  endpoint('/single_object_association') do
    get(HashDealer.roll(:test_association_resource), :params => {})
    get(HashDealer.roll(:active_test_association_resource), :params => {:active => true})
    get(HashDealer.roll(:active_birthday_test_association_resource), :params => {:active => true, :birthday => true})
    get(HashDealer.roll(:inactive_birthday_test_association_resource), :params => {:active => false, :birthday => true})
  end

  endpoint("/mock_with_block/:id") do
    get({:abc => 123}, {:params => {:test => "123"}.matcher}) do |params|
      self[:test] = params[:test]
      self[:id] = params[:id]
      self
    end
  end

  endpoint('/multi_object_association') do
    get((0..4).to_a.collect{HashDealer.roll(:test_association_resource)}, :params => {})
    get((0..4).to_a.collect{HashDealer.roll(:active_test_association_resource)}, :params => {:active => true})
    get((0..4).to_a.collect{HashDealer.roll(:active_test_association_resource)}, :params => {:active => false})
    get((0..4).to_a.collect{HashDealer.roll(:active_birthday_test_association_resource)}, :params => {:active => true, :birthday => true})
  end

  endpoint("/has_one_objects/new") do
    get({
      "attributes" => {
        "public" => ["size", "color"]
      }
    })
  end
  
  endpoint("/has_many_objects/new") do
    get({
      "attributes" => {
        "public" => ["name"]
      }
    })
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

  endpoint("/test_throughs/new") do
    get({})
  end
  
end
