# Ensure ActionCable's solid_cable adapter reconnects after SolidQueue forks a worker
# This is necessary because forked processes don't inherit database connections

SolidQueue.on_worker_start do
  # Force ActionCable to reconnect its pubsub adapter
  # This ensures broadcasts from background jobs reach the cable database
  ActionCable.server.pubsub.send(:connect) if ActionCable.server.pubsub.respond_to?(:connect, true)
end
