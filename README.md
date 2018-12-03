
这里以安装 redis 3.2 为例，如果要安装其他版本，将3.2换为要安装的版本即可

## 获取 redis 镜像

    docker pull redis:3.2

## 查看已经下载的镜像

    docker images

## 创建容器

* 创建存放 redis 容器的目录

```sh
# 创建存放 redis 容器的目录
mkdir -p ~/docker/redis/{conf,data}
cd ~/docker/redis
```

* 获取 redis 的默认配置模版

```sh
# 获取 redis 的默认配置模版
# 这里主要是想设置下 redis 的 log / password / appendonly
# redis 的 docker 运行参数提供了 --appendonly yes 但没 password
wget https://raw.githubusercontent.com/antirez/redis/3.2/redis.conf -O conf/redis.conf

# 直接替换编辑
sed -i 's/logfile ""/logfile "access.log"' conf/redis.conf
sed -i 's/# requirepass foobared/requirepass 123456' conf/redis.conf
sed -i 's/appendonly no/appendonly yes' conf/redis.conf

# 这里可能还需配置一些 bind protected-mode
```

> protected-mode 是在没有显示定义 bind 地址（即监听全网断），又没有设置密码 requirepass 时，只允许本地回环 127.0.0.1 访问。 也就是说当开启了 protected-mode 时，如果你既没有显示的定义了 bind s监听的地址，同时又没有设置 auth 密码。那你只能通过 127.0.0.1 来访问 redis 服务。

* 创建并运行一个名为 myredis 的容器

```sh
# 创建并运行一个名为 myredis 的容器
docker run \
-p 6379:6379 \
-v $PWD/data:/data \
-v $PWD/conf/redis.conf:/etc/redis/redis.conf \
--privileged=true \
--name myredis \
-d redis:3.2 redis-server /etc/redis/redis.conf
```

* 使用 `host模式` 创建并运行一个名为 myredis 的容器

```sh
docker run \
--network host \
-v $PWD/data:/data \
-v $PWD/conf/redis.conf:/etc/redis/redis.conf \
--privileged=true \
--name myredis \
-d redis:3.2 redis-server /etc/redis/redis.conf
```

* 命令分解

```sh
docker run \
-p 6379:6379 \ # 端口映射 宿主机:容器; 将容器的6379端口映射到主机的6379端口
-v $PWD/data:/data:rw \ # 映射数据目录 rw 为读写
-v $PWD/conf/redis.conf:/etc/redis/redis.conf:ro \ # 挂载配置文件 ro 为readonly
--privileged=true \ # 给与一些权限
--name myredis \ # 给容器起个名字
-d redis:3.2 redis-server /etc/redis/redis.conf # deamon 守护进程运行服务使用指定的配置文件
# 另外AOF持久化可以通过参数进行配置：
redis-server --appendonly yes # 打开 AOF 持久化
```

* 查看活跃的容器

```sh
# 查看活跃的容器
docker ps
# 如果没有 myredis 说明启动失败 查看错误日志
docker logs myredis
# 查看 myredis 的 ip 挂载 端口映射等信息
docker inspect myredis
# 查看 myredis 的端口映射
docker port myredis
# 查看所有容器
docker ps -a
```

## 内部访问 redis 容器服务

```sh
# redis-cli 访问
docker exec -it myredis redis-cli
# -it 交互的虚拟终端
```

配置完成

## 主从配置

新建容器 redis-slave
```sh
# 创建并运行一个名为 redis-slave 的容器
docker run \
-p 6378:6378 \
-v $PWD/data:/data \
-v $PWD/conf/slave.conf:/etc/redis/slave.conf \
--privileged=true \
--name redis-slave \
-d redis:3.2 redis-server /etc/redis/slave.conf
```

查看 redis master 的内部 ip

```sh
docker inspect myredis | grep IPAddress
# 可以得到 redis master 的 ip 地址
```

修改 redis-slave 的配置文件

```sh
vim conf/slave.conf

# 从服务器端口
port 6378
# 主地址 master-ip 改为上一步得到的 redis master 的 ip 地址
slaveof master-ip 6379
# 数据持久化 目录
dir ../data/slave
# The name of the append only file
appendfilename "appendonly_slave.aof"
# 主认证
masterauth
```

重启 redis-slave

```sh
docker restart redis-slave
# redis-cli 访问 redis-slave
docker exec -it redis-slave redis-cli -p 6378
```

登录 redis master 使用 info 命令查看从的状态

如果配置不成功记得检查 redis master 的 bind 和 protected-mode 的设置，看下有没有监听内网地址，否则 redis-slave 没办法通过 redis master 的地址做数据同步

## 其他命令

```sh
# 启动容器 已经停止的容器，我们可以使用命令 docker start 来启动。
docker start myredis
#正在运行的容器，我们可以使用 docker restart 命令来重启
docker restart myredis
# 停止容器
docker stop myredis
# 删除容器 删除容器时，容器必须是停止状态，否则会错
docker rm myredis
```


