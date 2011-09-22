HashDealer.define(:new_test_object) do
  attributes({
    :protected => [:id],
    :public => [:name, :age],
  })
  scopes([
    {:active => {:active => true}},
    {:paginate => {:paginate => true, :per_page => :per_page, :current_page => :current_page}}
  ])
  associations({
    :has_many => {:has_many_objects => {}},
    :belongs_to => {:belongs_to_object => {}, :custom_name => {:class_name => "BelongsToObject"}},
    :has_one => {:has_one_object => {}},
  })
  # Think of a use case for this
  options({
    
  })
end

HashDealer.define(:test_resource) do
  name("name")
  age("age")
end

HashDealer.define(:test_resource_errors) do
  errors({
    :name => ["can't be blank"],
    :age => ["must be a valid number"]
  })
end