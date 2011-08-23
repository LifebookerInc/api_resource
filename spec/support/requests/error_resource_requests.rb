HashDealer.define(:new_error_resource) do
  attributes({
    :protected => [:id],
    :public => [:name, :age],
  })
end

HashDealer.define(:error_resource) do
  name("Name")
  age("age")
end

HashDealer.define(:error_resource_errors) do
  errors({
    :name => ["must not be empty"],
    :age => ["must be a valid integer"]
  })
end

HashDealer.define(:error_resource_full_message_errors) do
  errors([
    "Name cannot be empty",
    "Age must be a valid integer"
  ])
end