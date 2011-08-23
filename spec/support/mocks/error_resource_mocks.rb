include ApiResource

Mocks.define do
  
  endpoint("/error_resources/new") do
    get(HashDealer.roll(:new_error_resource))
  end

  endpoint("/error_resources") do
    post(HashDealer.roll(:error_resource_errors), :params => {:error_resource => HashDealer.roll(:error_resource).matcher}, :status_code => 422)
  end
  
  endpoint("/error_full_message_resources/new") do
    get(HashDealer.roll(:new_error_resource))
  end

  endpoint("/error_full_message_resources") do
    post(HashDealer.roll(:error_resource_full_message_errors), :params => {:error_full_message_resource => HashDealer.roll(:error_resource).matcher}, :status_code => 422)
  end
  
end