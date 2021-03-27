# Traefik-client

- Вытягивает с [traefik-api](../traefik/readme.MD) сертификаты через `ssh`.
- Перезапускает нужный сервис

1. Заполняем `.env` файл нужными значениями.
2. Генерируем на машине, которой нужны сертификаты, ssh-ключ, чтобы ходить на машину с `traefik`

```
ssh-keygen
```

3. копируем их на машину с `traefik`

```
ssh-copy-id root@traefik_ip
```

4. настраиваем `crontab` на регулярные обновления

```
30 07 * *\1 * cd /srv/services/traefik-client/ && ./getcert.sh
```
