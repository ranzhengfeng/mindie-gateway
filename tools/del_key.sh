#!/usr/bin/env bash
# 删除 Redis 中的 API Key
# 用法: ./del_key.sh <API_KEY>
KEY="$1"
if [ -z "$KEY" ]; then
  echo "Usage: $0 <API_KEY>"
  exit 1
fi
docker exec -i mindie-redis redis-cli -a "Corem@2025!" del "apikey:$KEY"
echo "Deleted apikey:$KEY"
