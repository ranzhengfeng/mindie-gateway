#!/usr/bin/env bash
# 添加 API Key 到 Redis
# 用法: ./add_key.sh <API_KEY> <DESCRIPTION>
KEY="$1"
DESC="$2"

if [ -z "$KEY" ] || [ -z "$DESC" ]; then
  echo "Usage: $0 <API_KEY> <DESCRIPTION>"
  exit 1
fi

# 添加到 Redis
docker exec mindie-redis redis-cli -a "Corem@2025!" \
  HSET "apikey:$KEY" "desc" "$DESC"

echo "Added $KEY ($DESC)"

