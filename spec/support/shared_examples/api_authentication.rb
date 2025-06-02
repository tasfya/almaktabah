RSpec.shared_examples "API authentication required" do |request_proc|
  it "returns unauthorized without a valid token" do
    # Make the request without any authentication
    instance_eval(&request_proc) if request_proc
    
    # Expect unauthorized response
    expect(response).to have_http_status(:unauthorized)
    expect(json_response).to include("error")
    expect(json_response["error"]).to eq("Unauthorized")
  end
  
  it "allows access with a valid API token" do
    # Make the request with an API token
    headers = with_api_token
    instance_exec(headers, &request_proc) if request_proc
    
    # Expect successful response
    expect(response).to have_http_status(:ok)
  end
  
  it "allows access with a valid JWT token" do
    # Make the request with a JWT token
    user = create(:user)
    headers = with_user_token(user)
    instance_exec(headers, &request_proc) if request_proc
    
    # Expect successful response
    expect(response).to have_http_status(:ok)
  end
end
