docker-compose down -v --remove-orphans
rm -rf ./opencart_data  # Cleaning up previous host folders
docker-compose up --build -d
sleep 10
docker ps
