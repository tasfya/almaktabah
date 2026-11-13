require "rails_helper"

RSpec.describe CloudflareClientIp do
  let(:app) do
    stack = ->(env) { [ 200, {}, [ ActionDispatch::Request.new(env).remote_ip ] ] }
    ActionDispatch::RemoteIp.new(described_class.new(stack))
  end

  # Production shape: Thruster on loopback, kamal-proxy on the Docker network,
  # and kamal-proxy's own X-Forwarded-For naming whoever connected to it.
  def remote_ip(peer:, cf_connecting_ip: nil)
    env = Rack::MockRequest.env_for("/", "REMOTE_ADDR" => "127.0.0.1", "HTTP_X_FORWARDED_FOR" => "#{peer}, 172.18.0.5")
    env["HTTP_CF_CONNECTING_IP"] = cf_connecting_ip if cf_connecting_ip
    app.call(env).last.first
  end

  it "uses CF-Connecting-IP when a Cloudflare edge connected" do
    expect(remote_ip(peer: "172.71.178.144", cf_connecting_ip: "203.0.113.7")).to eq("203.0.113.7")
  end

  it "accepts an IPv6 visitor behind an IPv6 edge" do
    expect(remote_ip(peer: "2606:4700:10::1", cf_connecting_ip: "2001:db8::42")).to eq("2001:db8::42")
  end

  it "keeps the peer when someone reaches the origin directly with a forged header" do
    expect(remote_ip(peer: "198.51.100.9", cf_connecting_ip: "203.0.113.7")).to eq("198.51.100.9")
  end

  it "keeps the edge address when the header is not an IP" do
    expect(remote_ip(peer: "172.71.178.144", cf_connecting_ip: "not an ip")).to eq("172.71.178.144")
  end

  it "keeps the peer when Cloudflare sends no header" do
    expect(remote_ip(peer: "172.71.178.144")).to eq("172.71.178.144")
  end
end
