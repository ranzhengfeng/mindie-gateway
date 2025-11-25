#!/usr/bin/env bash
# 列出 Redis 中的所有 API Key 及其描述
# 用法: ./list_keys.sh
docker exec mindie-redis redis-cli -a "Corem@2025!" keys "apikey:*" | while read k; do
  desc=$(docker exec mindie-redis redis-cli -a "Corem@2025!" HGET "$k" desc)
  echo "Key: $k  |  Desc: $desc"
done

