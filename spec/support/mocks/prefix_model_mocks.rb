ApiResource::Mocks.define do
	endpoint("/prefix_models/new.json") do
		get(HashDealer.roll(:new_prefix_model_response))
	end
end