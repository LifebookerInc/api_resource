HashDealer.define(:new_test_object) do
  attributes({
    protected: [
      [:id, :integer],
      :protected_attr
    ],
    public: [
      [:name, :string],
      :age,
      [:is_active, :boolean],
      :belongs_to_object_id,
      :custom_name_id,
      [:bday, :date],
      [:roles, :array]
    ]
  })
  scopes({
    active: {},
    birthday: {
      date: :req
    },
    boolean: {
      a: :opt,
      b: :opt
    }

  })
  associations({
    has_many: {
      has_many_objects: {},
      has_many_service_uri: {
        class_name: "HasManyObject"
      }
    },
    belongs_to: {belongs_to_object: {}, custom_name: {class_name: "BelongsToObject"}},
    has_one: {has_one_object: {}},
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

HashDealer.define(:test_resource_with_proxies, parent: :test_resource) do
  has_one_object{HashDealer.roll(:has_one_object)}
  has_many_objects{(0..4).to_a.collect{HashDealer.roll(:has_many_object)}}
  has_many_service_uri{[{service_uri: "/test_resource/1/has_many"}]}
  belongs_to_object({service_uri: "/belongs_to_objects/4"})
end

HashDealer.define(:test_resource_errors) do
  errors({
    name: ["can't be blank"],
    age: ["must be a valid number"]
  })
end
