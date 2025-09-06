# Stop and remove old containers
docker-compose down -v --remove-orphans

# Remove old volumes if they exist
docker volume rm opencart-docker_opencart_data || true
docker volume rm opencart-docker_db_data || true

# Clean up any local override folders (if they exist)
rm -rf ./opencart_data

# Rebuild and start fresh containers in detached mode
docker-compose up -d --force-recreate --remove-orphans

# Wait a bit for services to start
sleep 10

# List running containers
docker ps

# Verify that OpenCart files exist inside the container
docker exec -it opencart-web ls -la /var/www/html

