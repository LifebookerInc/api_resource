HashDealer.define(:test_association_resource) do
  id{Kernel.rand(99999)}
  name{Faker::Name.first_name}
  age{Kernel.rand(99999)}
  active(false)
end

HashDealer.define(:active_test_association_resource, :parent => :test_association_resource) do
  active(true)
end

HashDealer.define(:active_birthday_test_association_resource, :parent => :active_test_association_resource) do
  birthday{Date.today}
end

HashDealer.define(:has_one_object) do
	size("large")
	color("blue")
end

HashDealer.define(:has_many_object) do
	name("name")
end