# Idempotency — Order Service. Homework 9

**Паттерн:** Client-Supplied Idempotency Key (ключ идемпотентности)

Клиент передаёт UUID в заголовке `Idempotency-Key`. Первый запрос -> **202**, повторный -> **200** с тем же заказом.

## Состав

Полная distributed transaction (Saga с оркестрацией) + идемпотентный order-service:

| Сервис | Образ |
|--------|-------|
| auth-service | `mblkuta/auth-service:latest` |
| profile-service | `mblkuta/profile-service:0.3.0` |
| billing-service | `mblkuta/billingsvc:0.3.1` |
| **order-service** | **`mblkuta/ordersvc:hw9-v2`** (идемпотентный!) |
| notification-service | `mblkuta/notificationsvc:0.3.0` |
| warehouse-service | `mblkuta/warehousesvc:0.1.0` |
| delivery-service | `mblkuta/deliverysvc:0.1.0` |
| rabbitmq | `rabbitmq:3.13-management-alpine` |
| postgres (7 шт) | `postgres:16-alpine` |
| traefik | Ingress |

## Установка

```bash
cd idempotency
helm install arch-homework ./helm --namespace arch-homework --create-namespace --wait --timeout 10m
kubectl get pods -n arch-homework
```

## Проверка идемпотентности

```bash
kubectl port-forward -n arch-homework svc/order-service 8089:80 &

IDKEY=$(uuidgen)
# первый запрос — 202
curl -s -w '\nHTTP: %{http_code}\n' -X POST http://localhost:8089/api/v1/order \
  -H "Idempotency-Key: $IDKEY" -H 'x-user-id: 42' \
  -H 'Content-Type: application/json' -d '{"price":1500.50}'

# повторный — 200 (тот же order.id)
curl -s -w '\nHTTP: %{http_code}\n' -X POST http://localhost:8089/api/v1/order \
  -H "Idempotency-Key: $IDKEY" -H 'x-user-id: 42' \
  -H 'Content-Type: application/json' -d '{"price":1500.50}'
```

## Postman

Коллекция: `./idempotency-tests.postman_collection.json`
`{{baseUrl}} = http://arch.homework`

## Прогон тестов через Newman

```bash
# Установка Newman
npm install -g newman

# Прогон (предварительно сделайте port-forward)
kubectl port-forward -n arch-homework svc/order-service 8089:80 &

newman run ./idempotency-tests.postman_collection.json \
  --env-var "baseUrl=http://localhost:8089" \
  --reporters cli

# Или через Ingress (если arch.homework настроен на кластер)
newman run ./idempotency-tests.postman_collection.json \
  --env-var "baseUrl=http://arch.homework" \
  --reporters cli
```