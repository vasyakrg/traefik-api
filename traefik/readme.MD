# Traefik server for docker

- поднимает траефик в докере
- позволяет выпускать наружу другие сервисы как в докере, так и из локальной сети подставляя валидные SSL сертификаты
- traefik-api умеет отдавать сертификаты по запросу через `токен`

## Настройка

- заполнить `.env` из `.env.example`
- запустить `./init.sh` (делается первый и единственный раз)
- запустить сервис

```
docker-compose up -d
```

- добавить в крон дампер, который из файла `acme.json` вытягивает и раскладывает сертификаты по папкам с названием доменов (нужно, что бы корректно работал `traefik-api`)

```
25 07 * *\1 * cd /srv/services/traefik/ && ./dumper.sh >> /var/log/traefik_api.log
```

**Внимание!**, что бы правильно работал `dumper.sh` в системе должна быть установлена утилита `jq`

```
apt install jq - для Debian\Ubuntu
brew install jq -  для MacOS
```

## Внешняя защита

- Так как сам сервис trafik доступен из вне, его так же логично закрыть хотя бы basic auth
- в файле docker-compose.yml раскомментим строки:

```
- ./data/basic.auth:/basic.auth
- "traefik.http.middlewares.traefik-auth.basicAuth.usersFile=/basic.auth"
- "traefik.http.routers.traefik.middlewares=traefik-auth"
```

в папку `data` сгенерим файлик `basic.auth` c логином и паролем

```
htpasswd -c data/basic.auth admin
```


## Докерные сервисы

- запускаем нужный контейнер с правильно выставленными `лейблами`
- контейнер должен быть в том числе подключен к сети `webproxy`

**Пример**:

```
version: '3.7'
services:
    grafana:
      container_name: grafana
      image: grafana/grafana:latest
      restart: always
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.grafana.entrypoints=https"
        - "traefik.http.routers.grafana.rule=Host(`grafana.domain.ru`)"
        - "traefik.http.routers.grafana.tls=true"
        - "traefik.http.routers.grafana.tls.certresolver=letsEncrypt"
        - "traefik.http.services.grafana-service.loadbalancer.server.port=3000"
        - "traefik.docker.network=webproxy"
      environment:
        - GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD}
        - GF_SECURITY_ADMIN_USER=${GF_SECURITY_ADMIN_USER}
        - GF_AUTH_ANONYMOUS_ENABLED=false
        - GF_USERS_ALLOW_SIGN_UP=false
        - GF_USERS_ALLOW_ORG_CREATE=false
      volumes:
        - grafana:/var/lib/grafana
      expose:
        - 3000
      networks:
        - grafana_net
        - webproxy
```

## Кастомные сервисы

- примеры кастомных сервисов (читать - сервисы не в докере, а в локальной сети) лежат в папке `data/custom`
- файл должен иметь вид `name.yml` и содержать в себе правильный контекст (проверить ошибки применения можно через `docker log <traefik_container>`)
- перезапускать траефик, что бы применить новые файлы `не нужно!`
- если сервис больше не нужен, файл удаляется руками или переносится в папку disabled (опять же траефик применяет изменения налету)

## Traefik API

- Позволяет отдавать сертификаты в [traefik-api-client](../traefik-api-client/readme.MD) или по запросу
- В `.env` в переменной `ADMIN_TOKEN` указываем наш стойкий токен

### Методы для работы с API:

#### авторизация:

```
'headers' => [
    'Authorization' => 'Bearer ' . $TOKEN,
]
```

#### проверка, что у traefik есть нужный домен:

```
curl -s --request POST 'https://traefik-api.domain.ru/api/v1/certman/getdomain' \
     --header 'Authorization: Bearer <token>' \
     --form 'domain=domain.ru'
```

#### запрос ключей:

```
curl -s --request POST 'https://traefik-api.domain.ru/api/v1/certman/getcerts' \
     --header 'Authorization: Bearer <token>' \
     --form 'domain=domain.ru'
```

#### корректный вывод будет такой:

```
{
    "success": true,
    "data": {
        "crt": "-----BEGIN CERTIFICATE-----\\...\\-----END CERTIFICATE-----",
        "key": "-----BEGIN PRIVATE KEY-----\\...\\-----END PRIVATE KEY-----",
        "chain": "-----BEGIN CERTIFICATE-----\\...\\-----END CERTIFICATE-----"
    },
    "message": "OK"
}
```
