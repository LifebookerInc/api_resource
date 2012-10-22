HashDealer.define(:new_test_object) do
  attributes({
    :protected => [:id],
    :public => [:name, :age, :is_active, [:bday, :date], [:roles, :array]]
  })
  scopes({
    :active => {:active => :opt},
    :paginate => {:per_page => :opt, :current_page => :opt}
  })
  associations({
    :has_many => {:has_many_objects => {}},
    :belongs_to => {:belongs_to_object => {}, :custom_name => {:class_name => "BelongsToObject"}},
    :has_one => {:has_one_object => {}},
  })
end

HashDealer.define(:test_resource) do
  name("name")
  age("age")
end

HashDealer.define(:test_resource_with_roles) do
  name("name")
  age("age")
  roles([])
end

HashDealer.define(:test_resource_with_proxies, :parent => :test_resource) do
  has_one_object{HashDealer.roll(:has_one_object)}
  has_many_objects{(0..4).to_a.collect{HashDealer.roll(:has_many_object)}}
end

HashDealer.define(:test_resource_errors) do
  errors({
    :name => ["can't be blank"],
    :age => ["must be a valid number"]
  })
end
