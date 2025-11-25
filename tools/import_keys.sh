#!/usr/bin/env bash
# 批量导入 API Key 到 Redis
# 用法: ./import_keys.sh <file> (文件格式: 每行 "API_KEY DESCRIPTION")

FILE="$1"
if [ -z "$FILE" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

# 去掉 CRLF
sed -i 's/\r$//' "$FILE"

while IFS= read -r line || [ -n "$line" ]; do
  # 跳过空行
  if [ -n "$line" ]; then
    key=$(echo "$line" | awk '{print $1}')
    desc=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ //')

    docker exec mindie-redis redis-cli -a "Corem@2025!" \
      HSET "apikey:$key" "desc" "$desc"
    echo "Added $key ($desc)"
  fi
done < "$FILE"

