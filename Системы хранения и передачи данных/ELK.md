# Домашнее задание к занятию "`ELK`" - `Туркменов Роман`

Для выполнения заданий использован Docker Compose. Elasticsearch, Kibana, Logstash, Nginx и Filebeat запускаются в отдельных контейнерах. 
Для хранения данных Elasticsearch и передачи логов Nginx используются Docker volumes. Конфигурация всех сервисов приведена в файле [docker-compose](https://github.com/albonese1337/homework/blob/main/img-and-file/docker-compose.yml)

## Задание 1. Elasticsearch 

Установите и запустите Elasticsearch, после чего поменяйте параметр cluster_name на случайный. 

*Приведите скриншот команды 'curl -X GET 'localhost:9200/_cluster/health?pretty', сделанной на сервере с установленным Elasticsearch. Где будет виден нестандартный cluster_name*.

### Решение:
В сервисе Elasticsearch настраиваем:
```
environment:
  - cluster.name=turkmenov
```

Проверяем:
```
curl -X GET 'localhost:9200/_cluster/health?pretty'
```

![curl](https://github.com/albonese1337/homework/blob/main/img-and-file/zadan1.PNG)

---

## Задание 2. Kibana

Установите и запустите Kibana.

*Приведите скриншот интерфейса Kibana на странице http://<ip вашего сервера>:5601/app/dev_tools#/console, где будет выполнен запрос GET /_cluster/health?pretty*.

### Решение:


Kibana запущена через Docker Compose и подключена к Elasticsearch по адресу http://elasticsearch:9200. В интерфейсе Dev Tools выполнен запрос GET /_cluster/health?pretty

![kibana](https://github.com/albonese1337/homework/blob/main/img-and-file/zadan2.PNG)
---
## Задание 3. Logstash

Установите и запустите Logstash и Nginx. С помощью Logstash отправьте access-лог Nginx в Elasticsearch. 

*Приведите скриншот интерфейса Kibana, на котором видны логи Nginx.*

## Решение:

### Настройка Nginx:

Создан файл nginx/default.conf с настройкой виртуального сервера и записи access-логов.
```

server {
    listen 80;
    server_name localhost;

    access_log /var/log/nginx/access.log combined;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}

```
Nginx принимает HTTP-запросы на порту 80 и записывает access-логи в /var/log/nginx/access.log.

### Настройка logstash:
Создан файл logstash/logstash.conf:
```
input {
  file {
    path => "/var/log/nginx/access.log"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "nginx-logstash-%{+YYYY.MM.dd}"
  }
}

```
Logstash читает access-лог Nginx и отправляет записи в Elasticsearch. Для хранения используется индекс nginx-logstash-* с датой в имени.

### Запускаем сервисы и проверяем:

Отправляем HTTP запросы к Nginx:
```
for i in 1 2 3; do
  curl -s -o /dev/null http://localhost:8080/
done
```

Проверяем наличие логов в Nginx и Logstash:
```
docker compose exec nginx tail -n 5 /var/log/nginx/access.log
docker compose exec logstash tail -n 5 /var/log/nginx/access.log
```
Проверяем количество документов в Elasticsearch:
```
curl -s 'localhost:9200/nginx-logstash-*/_count?pretty'
```

### Проверка Kibana:
Открываем Kibana по адресу -> http://192.168.1.105:5601

В разделе Stack Management -> Index Patterns создаём шаблон: nginx-logstash-*

В качестве временного поля выбираем @timestamp.

Переходим в Discover, выбираем созданный шаблон и устанавливаем подходящий временной диапазон.

в Kibana отображаются три документа (3 hits) с access-логами Nginx, содержащими HTTP-запросы GET / HTTP/1.1 и код ответа 200.

![kibana](https://github.com/albonese1337/homework/blob/main/img-and-file/zadan3.PNG)







---

## Задание 4. Filebeat. 

Установите и запустите Filebeat. Переключите поставку логов Nginx с Logstash на Filebeat. 

*Приведите скриншот интерфейса Kibana, на котором видны логи Nginx, которые были отправлены через Filebeat.*


## Решение:
Останавливаем Logstash, чтобы он больше не отправлял новые логи. Filebeat будет читать тот же access-лог напрямую и писать события в отдельный индекс Elasticsearch.
Создаём `filebeat.yml`:
```
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/log/nginx/access.log

output.elasticsearch:
  hosts: ["http://elasticsearch:9200"]
  index: "nginx-filebeat-%{+yyyy.MM.dd}"

setup.ilm.enabled: false
setup.template.enabled: false
```

Отправляем HTTP запросы:
```
for i in 1 2 3; do
  curl -s -o /dev/null http://localhost:8080/
done
```
Проверяем документы в Elasticsearch:

```
curl -s 'localhost:9200/nginx-filebeat-*/_count?pretty'
```

![filebeat-kibana](https://github.com/albonese1337/homework/blob/main/img-and-file/zadan4.PNG)
