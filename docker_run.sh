if [ "$1" == "cli" ]; then
  docker exec -it myredis redis-cli
  exit
fi

if [ "$1" == "bash" ]; then
  docker exec -it myredis bash
  exit
fi

echo Docker Images:
docker images
if [ $? -ne 0 ]; then
  echo "请确认已开启 Docker！"
  exit
fi
echo

echo Docker Containers:
docker ps -a -f 'name=myredis'
if [ $? -eq 0 ]; then
  echo
  echo already created myredis container
  echo start myredis container...
  docker start myredis || docker restart myredis
else
  echo
  docker run \
  -p 6379:6379 \
  -v $PWD/data:/data \
  -v $PWD/conf/redis.conf:/etc/redis/redis.conf \
  --privileged=true \
  --name myredis \
  -d redis:3.2 redis-server /etc/redis/redis.conf
fi


