require "ipaddr"

# Production runs behind Cloudflare, then kamal-proxy. kamal-proxy (TLS on,
# header forwarding off) writes X-Forwarded-For itself, so Rails' remote_ip is
# the Cloudflare edge that connected, not the visitor. Turning forwarding on is
# not an option: it would also pass a client-supplied X-Forwarded-Host, which
# picks the tenant.
#
# When the connecting peer is a Cloudflare edge, Cloudflare's CF-Connecting-IP
# names the visitor. Anyone reaching the origin directly is their own peer, so
# a forged header from them is ignored.
class CloudflareClientIp
  # https://www.cloudflare.com/ips (check now and then; a stale list only falls
  # back to the edge address).
  RANGES = %w[
    173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 141.101.64.0/18
    108.162.192.0/18 190.93.240.0/20 188.114.96.0/20 197.234.240.0/22 198.41.128.0/17
    162.158.0.0/15 104.16.0.0/13 104.24.0.0/14 172.64.0.0/13 131.0.72.0/22
    2400:cb00::/32 2606:4700::/32 2803:f800::/32 2405:b500::/32 2405:8100::/32
    2a06:98c0::/29 2c0f:f248::/32
  ].map { |range| IPAddr.new(range) }.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    visitor = visitor_ip(env)
    env["action_dispatch.remote_ip"] = visitor if visitor
    @app.call(env)
  end

  private

  def visitor_ip(env)
    header = env["HTTP_CF_CONNECTING_IP"]
    return if header.blank?

    peer = IPAddr.new(env["action_dispatch.remote_ip"].to_s)
    return unless RANGES.any? { |range| range.include?(peer) }

    IPAddr.new(header.strip).to_s
  rescue IPAddr::Error
    nil
  end
end
