# Kubernetes Hackathon

Одноузловой Kubernetes-кластер на Ubuntu 24.04 с веб-приложением Nginx, Gateway API, Prometheus и сбором логов через Fluentd.

## Архитектура

Client -> Envoy Gateway -> HTTPRoute -> Service -> Nginx Pod

Nginx logs -> Fluentd

Kubernetes / Node metrics -> Prometheus

## Использованные технологии

- Ubuntu 24.04.4 LTS
- Kubernetes v1.36.5
- kubeadm
- containerd 2.2.1
- Calico v3.33.0
- Envoy Gateway v1.9.2
- Gateway API
- Nginx 1.27
- Prometheus
- Fluentd 1.18
- Helm 3

## Структура проекта

kubernetes/
- app.yaml
- gateway-api.yaml

logging/
- fluentd.yaml

scripts/
- bootstrap.sh
- deploy.sh
- check.sh

Дополнительно:
- README.md
- VERSIONS.txt

## Развертывание

Окружение: Ubuntu Server 24.04.

### Создание Kubernetes-кластера

```bash
chmod +x scripts/*.sh
./scripts/bootstrap.sh
# Kubernetes Hackathon

Одноузловой Kubernetes-кластер на Ubuntu 24.04 с веб-приложением Nginx, публикацией через Gateway API, мониторингом Prometheus и сбором логов через Fluentd.

## Архитектура

```text
Client
  |
  v
Envoy Gateway
  |
  v
Gateway API / HTTPRoute
  |
  v
Service nginx
  |
  v
Nginx Pod
  |
  +---- container logs ----> Fluentd

Kubernetes / Node metrics ----> Prometheus
```

## Использованные технологии

- Ubuntu 24.04.4 LTS
- Kubernetes v1.36.5
- kubeadm
- containerd 2.2.1
- Calico v3.33.0
- Envoy Gateway v1.9.2
- Gateway API
- Nginx 1.27
- Prometheus
- Fluentd 1.18
- Helm 3

Точные версии компонентов тестового окружения также сохранены в `VERSIONS.txt`.

## Структура проекта

```text
.
├── kubernetes/
│   ├── app.yaml
│   └── gateway-api.yaml
├── logging/
│   └── fluentd.yaml
├── scripts/
│   ├── bootstrap.sh
│   ├── deploy.sh
│   └── check.sh
├── README.md
└── VERSIONS.txt
```

## Развертывание

Тестовое окружение:

- Ubuntu Server 24.04
- один Kubernetes control-plane node
- Kubernetes установлен через kubeadm
- container runtime: containerd

### 1. Подготовка Kubernetes-кластера

Сделать скрипты исполняемыми:

```bash
chmod +x scripts/*.sh
```

Запустить подготовку кластера:

```bash
./scripts/bootstrap.sh
```

Скрипт выполняет основные действия для подготовки Ubuntu 24.04:

- отключает swap;
- загружает необходимые kernel modules;
- настраивает sysctl;
- устанавливает containerd;
- включает `SystemdCgroup`;
- устанавливает kubelet, kubeadm и kubectl;
- выполняет `kubeadm init`;
- настраивает kubeconfig пользователя.

Для Kubernetes используется pod network CIDR:

```text
192.168.0.0/16
```

## 2. Установка Helm

Если Helm ещё не установлен:

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Проверка:

```bash
helm version
```

## 3. Развертывание компонентов

Запустить:

```bash
./scripts/deploy.sh
```

Скрипт автоматически устанавливает и настраивает:

- Calico;
- Envoy Gateway;
- Nginx;
- Gateway API resources;
- Fluentd;
- Prometheus.

Для одноузлового стенда снимается control-plane taint, чтобы workload мог запускаться на единственном узле.

## Проверка Kubernetes

Проверить состояние node:

```bash
kubectl get nodes -o wide
```

Ожидаемое состояние:

```text
STATUS   Ready
```

Проверить все Pod:

```bash
kubectl get pods -A
```

Основные компоненты должны находиться в состоянии `Running`.

Также доступен общий скрипт проверки:

```bash
./scripts/check.sh
```

## Веб-приложение

В качестве простого веб-приложения используется Nginx 1.27.

Приложение развернуто в namespace:

```text
hackathon
```

Проверка:

```bash
kubectl get pods -n hackathon
kubectl get svc -n hackathon
```

Service `nginx` имеет тип `ClusterIP` и направляет трафик на Nginx Pod по порту 80.

## Gateway API

Для публикации приложения используется Kubernetes Gateway API и Envoy Gateway.

Создаются следующие ресурсы:

- `GatewayClass` — `eg`;
- `Gateway` — `hackathon-gateway`;
- `HTTPRoute` — `nginx-route`;
- `Service` — `nginx`.

Проверка:

```bash
kubectl get gatewayclass
kubectl get gateway,httproute -n hackathon
```

Дополнительная проверка Envoy:

```bash
kubectl get pods -n envoy-gateway-system
kubectl get svc -n envoy-gateway-system
```

HTTPRoute направляет запросы:

```text
Envoy Gateway
      |
      v
HTTPRoute nginx-route
      |
      v
Service nginx:80
      |
      v
Nginx Pod
```

### Доступ к приложению

Тестовый кластер развернут локально в VirtualBox с помощью kubeadm.

В окружении отсутствует cloud LoadBalancer, поэтому автоматически созданный Envoy Service не получает внешний LoadBalancer IP и отображает:

```text
EXTERNAL-IP   <pending>
```

По этой же причине верхнеуровневый статус Gateway может отображать `PROGRAMMED=False` с причиной отсутствия назначенного LoadBalancer address.

При этом listener и HTTPRoute создаются Envoy Gateway, а HTTP-трафик доступен через NodePort Envoy Service.

Узнать назначенный NodePort:

```bash
kubectl get svc -n envoy-gateway-system
```

В тестовом окружении был назначен:

```text
80:30252/TCP
```

Проверка HTTP-запроса:

```bash
curl -i http://127.0.0.1:30252/
```

В ответ Nginx возвращает:

```text
HTTP/1.1 200 OK
```

Также был проверен запрос:

```bash
curl http://127.0.0.1:30252/test
```

Для отсутствующего пути Nginx корректно возвращает `404 Not Found`.

Таким образом подтверждается прохождение HTTP-трафика через Envoy Gateway и HTTPRoute к Kubernetes Service и Nginx Pod.

## Prometheus

Для мониторинга используется Prometheus.

Prometheus устанавливается через Helm в namespace:

```text
monitoring
```

Проверка:

```bash
kubectl get pods -n monitoring
```

В тестовом окружении запускаются:

- Prometheus Server;
- kube-state-metrics;
- Prometheus Node Exporter.

Prometheus Server должен иметь состояние:

```text
2/2 Running
```

### Persistent Storage

В локальном одноузловом kubeadm-кластере отсутствует StorageClass provisioner.

Поэтому для демонстрационного окружения persistent volume Prometheus отключен:

```text
server.persistentVolume.enabled=false
```

Это позволяет запускать Prometheus без внешней системы хранения.

### Проверка Prometheus

Для локального доступа выполнить:

```bash
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
```

После этого проверить готовность:

```bash
curl http://127.0.0.1:9090/-/ready
```

Ожидаемый результат:

```text
Prometheus Server is Ready.
```

Проверить сбор метрик можно PromQL-запросом:

```bash
curl 'http://127.0.0.1:9090/api/v1/query?query=up'
```

Успешный ответ API содержит:

```text
"status":"success"
```

Значения `up = 1` подтверждают наличие доступных targets и сбор метрик Prometheus.

## Fluentd

Для сбора логов приложения используется Fluentd.

Fluentd работает как Kubernetes DaemonSet.

Проверка:

```bash
kubectl get daemonset fluentd -n hackathon
```

Ожидается:

```text
DESIRED   1
READY     1
AVAILABLE 1
```

Fluentd читает container logs Nginx из:

```text
/var/log/containers/nginx-*_hackathon_*.log
```

Служебный position file Fluentd находится в:

```text
/tmp/fluentd-nginx.pos
```

В демонстрационной конфигурации Fluentd запускается с `runAsUser: 0`, поскольку ему требуется доступ к host container logs в `/var/log`.

Собранные записи направляются в stdout Fluentd.

### Проверка сбора access-логов

Сначала выполнить HTTP-запрос к приложению:

```bash
curl http://127.0.0.1:30252/
```

Затем посмотреть собранные Fluentd логи:

```bash
kubectl logs -n hackathon daemonset/fluentd --tail=50
```

Пример реально полученной записи:

```text
GET / HTTP/1.1
```

с HTTP-кодом:

```text
200
```

Это подтверждает работу цепочки:

```text
HTTP request
     |
     v
Envoy Gateway
     |
     v
HTTPRoute
     |
     v
Nginx
     |
     v
container log
     |
     v
Fluentd
```

## Автоматизация

В репозитории находятся три основных скрипта.

### `scripts/bootstrap.sh`

Подготавливает Ubuntu 24.04 и создает Kubernetes control-plane через kubeadm.

### `scripts/deploy.sh`

Автоматизирует развертывание:

- Calico;
- Envoy Gateway;
- приложения;
- Gateway API;
- Fluentd;
- Prometheus.

### `scripts/check.sh`

Показывает состояние основных компонентов решения:

```bash
./scripts/check.sh
```

Проверяются:

- Kubernetes node;
- приложение;
- Service;
- Gateway API;
- Prometheus;
- Fluentd;
- Envoy Gateway Service.

## Быстрая проверка решения

```bash
kubectl get nodes
kubectl get pods -A
kubectl get gateway,httproute -n hackathon
kubectl get svc -n envoy-gateway-system
kubectl get pods -n monitoring
kubectl get daemonset fluentd -n hackathon
```

Проверка приложения:

```bash
curl http://127.0.0.1:30252/
```

Проверка логирования:

```bash
kubectl logs -n hackathon daemonset/fluentd --tail=50
```

Проверка Prometheus:

```bash
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
```

В другом терминале:

```bash
curl 'http://127.0.0.1:9090/api/v1/query?query=up'
```

## Ограничения тестового окружения

Решение создавалось как демонстрационный одноузловой стенд.

Основные ограничения:

- один control-plane node;
- отсутствует cloud LoadBalancer;
- внешний IP Envoy Service остается `pending`;
- доступ к Envoy выполняется через NodePort;
- Prometheus работает без persistent storage;
- Fluentd читает host logs с правами root.

Эти ограничения относятся к локальному демонстрационному окружению и могут быть устранены при переносе решения в production-инфраструктуру.

## Масштабирование

Для production-среды решение можно расширить:

- добавить несколько control-plane и worker nodes;
- увеличить количество replicas Nginx;
- использовать внешний LoadBalancer;
- добавить persistent storage;
- добавить TLS для Gateway;
- использовать DNS;
- направлять Fluentd в Elasticsearch, OpenSearch, Loki или другое централизованное хранилище;
- добавить Grafana;
- добавить Alertmanager;
- настроить resource requests и limits;
- добавить NetworkPolicy;
- добавить readiness/liveness probes;
- использовать отдельные namespaces и RBAC-политики.

## Итог

В проекте реализованы:

- Kubernetes-кластер на Ubuntu 24.04;
- установка Kubernetes через kubeadm;
- containerd;
- Calico CNI;
- веб-приложение Nginx;
- Kubernetes Service;
- Envoy Gateway;
- Gateway API;
- GatewayClass;
- Gateway;
- HTTPRoute;
- Prometheus;
- Node Exporter;
- kube-state-metrics;
- Fluentd;
- автоматизированные скрипты развертывания и проверки.

Работа приложения, маршрутизации, мониторинга и сбора логов проверена в тестовом Kubernetes-кластере.
