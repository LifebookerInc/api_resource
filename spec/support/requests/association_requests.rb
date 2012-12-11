HashDealer.define(:test_association_resource) do
  id{Kernel.rand(99999)}
  name{Faker::Name.first_name}
  age{Kernel.rand(99999)}
  is_active(false)
end

HashDealer.define(:active_test_association_resource, :parent => :test_association_resource) do
  is_active(true)
end

HashDealer.define(:active_birthday_test_association_resource, :parent => :active_test_association_resource) do
  bday{Date.today}
end

HashDealer.define(:inactive_test_association_resource, :parent => :test_association_resource) do
  is_active(false)
end

HashDealer.define(:inactive_birthday_test_association_resource, :parent => :inactive_test_association_resource) do
  bday{Date.today}
end

HashDealer.define(:has_one_object) do
  size("large")
  color("blue")
end

HashDealer.define(:has_many_object) do
  name("name")
end
