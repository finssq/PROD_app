

echo "Ожидаем, пока MinIO станет доступным..."
until curl -s http://minio:9000/minio/health/ready; do
    echo "MinIO не доступен, пробуем снова..."
    sleep 5  
done

mc alias set myminio http://minio:9000 minioaccesskey miniosecretkey
mc mb myminio/my-bucket
mc anonymous set public myminio/my-bucket

echo "MinIO инициализирован успешно."
