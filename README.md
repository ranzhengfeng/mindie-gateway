# MindIE API 网关 + Redis API-Key 管理

华为MindIE推理框架默认不支持API-Key，本项目提供一个**API 网关**,支持**API-Key验证**，并将 API-Key 存储在 Redis 中。每个 API-Key 可关联 **描述信息**，用于标识分配给谁或用途。

---

## 功能特点

- API-Key 验证 API 接口
- Redis 后端，支持数据持久化
- 每个 API-Key 可存储描述信息（owner / 分配对象）
- 提供脚本：添加、导入、列出 API-Key
- 完全 Docker 化，基于 OpenResty/Nginx + Lua

---

##  Docker 部署

### 1. 启动容器

```bash
docker-compose up -d
````

* `api-gateway` 暴露端口 **8001**
* `redis` 存储 API-Key 和描述信息，数据持久化在 `./redis/data`

### 2. 查看日志

```bash
docker logs mindie-api-gateway
docker logs mindie-redis
```

---

##  Redis 配置

* Redis 启用了密码（在 `redis.conf` 中配置）：

```
requirepass Corem@2025!
```

* Lua 网关会自动使用此密码连接 Redis
* Redis 数据文件存储在 `./redis/data`，重启后仍然保留

---

##  脚本使用方法

### 1. 添加单个 API-Key

```bash
./tools/add_key.sh <API_KEY> "<描述信息>"
```

示例：

```bash
./tools/add_key.sh abc123 "Alice"
```

* 会在 Redis 中添加 `apikey:abc123`，Hash 字段 `desc=Alice`

### 2. 批量导入 API-Key

* 文件格式（`./tools/sample_keys.txt`）：

```
abc123 Alice
testkey-001 Bob
prod-key-999 TeamX
```

* 导入命令：

```bash
./tools/import_keys.sh ./tools/sample_keys.txt
```

* Redis 存储结构：

```
Key: apikey:<key>
Field "desc": <描述信息>
```

### 3. 列出所有 API-Key

```bash
./tools/list_keys.sh
```

输出示例：

```
Key: apikey:abc123       |  Desc: Alice
Key: apikey:testkey-001  |  Desc: Bob
Key: apikey:prod-key-999 |  Desc: TeamX
```

### 4. 删除API-Key
```bash
./tools/del_key.sh <API_KEY>
```

---

## API 调用示例

```bash
curl -v http://<HOST>:8001/v1/completions \
  -H "Authorization: Bearer abc123" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek_v32",
    "prompt": "You are a helpful assistant.",
    "stream": false,
    "temperature": 0,
    "max_tokens": 50
  }'
```

* 如果 API-Key 有效，返回 **200 OK**
* 如果 API-Key 无效，返回 **401 Unauthorized**

---

##  注意事项

* 描述信息存储在 **Redis Hash** 中，而非文件
* Lua 网关只验证 key 是否存在，不依赖描述信息
* Redis CLI 操作需使用密码：

```bash
docker exec mindie-redis redis-cli -a "Corem@2025!" HGETALL "apikey:abc123"
```

* `list_keys.sh` 会读取描述字段显示分配对象

---

##  推荐工作流程

1. 准备 `sample_keys.txt`，每行 key + 描述
2. 执行 `import_keys.sh` 导入 Redis
3. 用 `list_keys.sh` 查看所有 API-Key 与分配对象
4. 使用 `add_key.sh` 添加单个 API-Key
5. API Gateway 自动验证请求中的 Key

---

##  目录结构

```
mindie-gateway/
├─ docker-compose.yml
├─ nginx.conf
├─ lua/
│  └─ auth.lua
├─ redis/
│  ├─ redis.conf
│  └─ data/
├─ tools/
│  ├─ add_key.sh
│  ├─ import_keys.sh
│  ├─ list_keys.sh
│  └─ sample_keys.txt
```

## 开发者信息

**姓名**：冉正锋  
**邮箱**: rzf@corem.com.cn  