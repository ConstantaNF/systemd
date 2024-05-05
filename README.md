# ****Systemd - создание unit-файла**** #

### Описание домашннего задания ###

Выполнить следующие задания и подготовить развёртывание результата выполнения с использованием Vagrant и Ansible:
- Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig или в /etc/default).
- Установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).
- Дополнить unit-файл httpd (он же apache2) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.

### **Выполнение** ###

Задание выполняется на рабочей станции с ОС Ubuntu 22.04.4 LTS с заранее установленными Vagrant 2.4.1 и VirtualBox 7.0, а также Ansible 2.16.5 и Python 3.10.12.
Перед выполнением предварительно подготовлен репозиторий <https://github.com/ConstantaNF/systemd.git>

### **Подготовка окружения** ###

Для развёртывания управляемой ВМ посредством Vagrant создаю Vagrantfile в заранее подготовленном каталоге `/home/adminkonstantin/systemd`.

Стартую ВМ:

```
adminkonstantin@2OSUbuntu:~/systemd$ vagrant up
```

Подключаюсь к созданной ВМ по ssh:

```
adminkonstantin@2OSUbuntu:~/systemd$ vagrant ssh
```

Использую УЗ root:

```
[vagrant@systemd ~]$ sudo -i
```

### **Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig** ###

Для начала создаём файл `watchlog` с конфигурацией для сервиса в директории `/etc/sysconfig` - из неё сервис будет брать необходимые переменные:

```
[root@systemd ~]# cd /etc/sysconfig/
```

```
[root@systemd sysconfig]# touch watchlog
```

```
[root@systemd sysconfig]# nano watchlog 
```

```
# Configuration file for my watchlog service
# Place it to /etc/sysconfig

# File and word in that file that we will be monit
WORD="Started"
LOG=/var/log/watchlog.log













                                                                                        [ Read 7 lines ]
^G Get Help	 ^O Write Out     ^W Where Is	   ^K Cut Text      ^J Justify       ^C Cur Pos       M-U Undo         M-A Mark Text    M-] To Bracket   M-▲ Previous     ^B Back
^X Exit          ^R Read File     ^\ Replace	   ^U Uncut Text    ^T To Spell      ^_ Go To Line    M-E Redo         M-6 Copy Text    M-W WhereIs Next M-▼ Next         ^F Forward

```

Затем создаем `/var/log/watchlog.log` и пишем туда строки на своё усмотрение, плюс ключевое слово ‘error’:

```
[root@systemd sysconfig]# cd /var/log/
```

```
[root@systemd log]# cat /var/log/messages > /var/log/watchlog.log
```

Создадим скрипт:

```
[root@systemd log]# cd /opt
```

```
[root@systemd opt]# touch watchlog.sh
```

```
[root@systemd opt]# nano watchlog.sh 
```

```
#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi







                                                                                       [ Read 13 lines ]
^G Get Help	 ^O Write Out     ^W Where Is	   ^K Cut Text      ^J Justify       ^C Cur Pos       M-U Undo         M-A Mark Text    M-] To Bracket   M-▲ Previous     ^B Back
^X Exit          ^R Read File     ^\ Replace	   ^U Uncut Text    ^T To Linter     ^_ Go To Line    M-E Redo         M-6 Copy Text    M-W WhereIs Next M-▼ Next         ^F Forward
```

Команда logger отправляет лог в системный журнал.

Добавим права на запуск файла:

```
[root@systemd opt]# chmod +x watchlog.sh
```

Создадим юнит для сервиса:

```
[root@systemd system]# touch /etc/systemd/system/watchlog.service
```

```
[root@systemd system]# nano watchlog.service 
```

```
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG












                                                                                        [ Read 8 lines ]
^G Get Help	 ^O Write Out     ^W Where Is	   ^K Cut Text      ^J Justify       ^C Cur Pos       M-U Undo         M-A Mark Text    M-] To Bracket   M-▲ Previous     ^B Back
^X Exit          ^R Read File     ^\ Replace	   ^U Uncut Text    ^T To Spell      ^_ Go To Line    M-E Redo         M-6 Copy Text    M-W WhereIs Next M-▼ Next         ^F Forward
```

```
[root@systemd system]# chmod 664 /etc/systemd/system/watchlog.service
```

Создадим юнит для таймера:

```
[root@systemd system]# touch /etc/systemd/system/watchlog.timer
```

```
[root@systemd system]# nano watchlog.timer
```

```
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target










^G Get Help	 ^O Write Out     ^W Where Is	   ^K Cut Text      ^J Justify       ^C Cur Pos       M-U Undo         M-A Mark Text    M-] To Bracket   M-▲ Previous     ^B Back
^X Exit          ^R Read File     ^\ Replace	   ^U Uncut Text    ^T To Spell      ^_ Go To Line    M-E Redo         M-6 Copy Text    M-W WhereIs Next M-▼ Next         ^F Forward
```

```
[root@systemd system]# chmod 664 /etc/systemd/system/watchlog.timer
```

Стартуем timer:

```
[root@systemd system]# systemctl start watchlog.timer
```

Проверяем результат:

```
[root@systemd system]# tail -f /var/log/messages
```

```
May  1 14:04:25 magma systemd[1]: Started My watchlog service.
May  1 14:05:49 magma systemd[1]: Starting My watchlog service...
May  1 14:05:49 magma root[29441]: Wed May  1 14:05:49 UTC 2024: I found word, Master!
May  1 14:05:49 magma systemd[1]: watchlog.service: Succeeded.
May  1 14:05:49 magma systemd[1]: Started My watchlog service.
May  1 14:06:51 magma systemd[1]: Starting My watchlog service...
May  1 14:06:51 magma root[29446]: Wed May  1 14:06:51 UTC 2024: I found word, Master!
May  1 14:06:51 magma systemd[1]: watchlog.service: Succeeded.
May  1 14:06:51 magma systemd[1]: Started My watchlog service.
May  1 14:07:51 magma systemd[1]: Starting My watchlog service...
May  1 14:07:51 magma root[29452]: Wed May  1 14:07:51 UTC 2024: I found word, Master!
May  1 14:07:51 magma systemd[1]: watchlog.service: Succeeded.
```

### **Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно называться также.** ###

Устанавливаем spawn-fcgi и необходимые для него пакеты:

```
[root@systemd system]# yum install epel-release -y && yum install spawn-fcgi php php-cli -y
```

Раскомментируем строки с переменными в /etc/sysconfig/spawn-fcgi:

```
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 --/usr/bin/php-cgi"












^G Get Help	 ^O Write Out     ^W Where Is	   ^K Cut Text      ^J Justify       ^C Cur Pos       M-U Undo         M-A Mark Text    M-] To Bracket   M-▲ Previous     ^B Back
^X Exit          ^R Read File     ^\ Replace	   ^U Uncut Text    ^T To Spell      ^_ Go To Line    M-E Redo         M-6 Copy Text    M-W WhereIs Next M-▼ Next         ^F Forward
```

Создаём юнит spawn-fcgi.service:

```
[root@systemd system]# cd /etc/systemd/system/
```

```
[root@systemd system]# touch spawn-fcgi.service
```

```
[root@systemd system]# nano spawn-fcgi.service 
```

```
  GNU nano 2.9.8                                                                          spawn-fcgi.service                                                                          Modified  

[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target







^G Get Help	 ^O Write Out     ^W Where Is	   ^K Cut Text      ^J Justify       ^C Cur Pos       M-U Undo         M-A Mark Text    M-] To Bracket   M-▲ Previous     ^B Back
^X Exit          ^R Read File     ^\ Replace	   ^U Uncut Text    ^T To Spell      ^_ Go To Line    M-E Redo         M-6 Copy Text    M-W WhereIs Next M-▼ Next         ^F Forward
```

```
[root@systemd system]# chmod 664 /etc/systemd/system/spawn-fcgi.service 
```

Убеждаемся, что все успешно работает:

```
[root@systemd init.d]# systemctl start spawn-fcgi
```

```
[root@systemd init.d]# systemctl status spawn-fcgi
```

```
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2024-05-01 15:11:39 UTC; 7s ago
 Main PID: 30492 (php-cgi)
    Tasks: 33 (limit: 4617)
   Memory: 20.4M
   CGroup: /system.slice/spawn-fcgi.service
           ├─30492 /usr/bin/php-cgi
           ├─30498 /usr/bin/php-cgi
           ├─30499 /usr/bin/php-cgi
           ├─30500 /usr/bin/php-cgi
           ├─30501 /usr/bin/php-cgi
           ├─30502 /usr/bin/php-cgi
           ├─30503 /usr/bin/php-cgi
           ├─30504 /usr/bin/php-cgi
           ├─30505 /usr/bin/php-cgi
           ├─30506 /usr/bin/php-cgi
           ├─30507 /usr/bin/php-cgi
           ├─30508 /usr/bin/php-cgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2024-05-01 15:11:39 UTC; 7s ago
 Main PID: 30492 (php-cgi)
    Tasks: 33 (limit: 4617)
   Memory: 20.4M
   CGroup: /system.slice/spawn-fcgi.service
           ├─30492 /usr/bin/php-cgi
           ├─30498 /usr/bin/php-cgi
           ├─30499 /usr/bin/php-cgi
           ├─30500 /usr/bin/php-cgi
           ├─30501 /usr/bin/php-cgi
           ├─30502 /usr/bin/php-cgi
           ├─30503 /usr/bin/php-cgi
           ├─30504 /usr/bin/php-cgi
           ├─30505 /usr/bin/php-cgi
           ├─30506 /usr/bin/php-cgi
           ├─30507 /usr/bin/php-cgi
           ├─30508 /usr/bin/php-cgi
           ├─30509 /usr/bin/php-cgi
           ├─30510 /usr/bin/php-cgi
           ├─30511 /usr/bin/php-cgi
           ├─30512 /usr/bin/php-cgi
           ├─30513 /usr/bin/php-cgi
           ├─30514 /usr/bin/php-cgi
           ├─30515 /usr/bin/php-cgi
           ├─30516 /usr/bin/php-cgi
           ├─30517 /usr/bin/php-cgi
           ├─30518 /usr/bin/php-cgi
           ├─30519 /usr/bin/php-cgi
           ├─30520 /usr/bin/php-cgi
           ├─30521 /usr/bin/php-cgi
           ├─30522 /usr/bin/php-cgi
           ├─30523 /usr/bin/php-cgi
           ├─30524 /usr/bin/php-cgi
           ├─30525 /usr/bin/php-cgi
           ├─30526 /usr/bin/php-cgi
           ├─30527 /usr/bin/php-cgi
           ├─30528 /usr/bin/php-cgi
           └─30529 /usr/bin/php-cgi

May 01 15:11:39 systemd systemd[1]: Started Spawn-fcgi startup service by Otus.
```

### **Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами** ###

Для запуска нескольких экземпляров сервиса будем использовать шаблон в конфигурации файла окружения `/usr/lib/systemd/system/httpd.service`:

```
[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service

After=network.target remote-fs.target nss-lookup.target httpd-
init.service

Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

Создаём файлы окружения, в которых задается опция для запуска веб-сервера с необходимым конфигурационным файлом:

```
[root@systemd system]# cd /etc/sysconfig
```

```
[root@systemd sysconfig]# touch httpd-first
```

```
[root@systemd sysconfig]# touch httpd-second
```

```
[root@systemd sysconfig]# nano httpd-first 
```

```
  GNU nano 2.9.8                                                                             httpd-first                                                                                        

# /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf

















                                                                                        [ Read 3 lines ]
^G Get Help	 ^O Write Out     ^W Where Is	   ^K Cut Text      ^J Justify       ^C Cur Pos       M-U Undo         M-A Mark Text    M-] To Bracket   M-▲ Previous     ^B Back
^X Exit          ^R Read File     ^\ Replace	   ^U Uncut Text    ^T To Spell      ^_ Go To Line    M-E Redo         M-6 Copy Text    M-W WhereIs Next M-▼ Next         ^F Forward
```

```
[root@systemd sysconfig]# nano httpd-second
```

```
  GNU nano 2.9.8                                                                             httpd-second                                                                                       

# /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf

















                                                                                        [ Read 3 lines ]
^G Get Help	 ^O Write Out     ^W Where Is	   ^K Cut Text      ^J Justify       ^C Cur Pos       M-U Undo         M-A Mark Text    M-] To Bracket   M-▲ Previous     ^B Back
^X Exit          ^R Read File     ^\ Replace	   ^U Uncut Text    ^T To Spell      ^_ Go To Line    M-E Redo         M-6 Copy Text    M-W WhereIs Next M-▼ Next         ^F Forward
```

Соответственно в директории с конфигами httpd `/etc/httpd/conf` должны лежать два конфига, в нашем случае это будут first.conf и second.conf:

```
[root@systemd sysconfig]# cd /etc/httpd/conf
```

```
[root@systemd conf]# mv httpd.conf first.conf
```

```
[root@systemd conf]# cp first.conf second.conf
```

Для удачного запуска, в конфигурационных файлах должны быть указаны уникальные для каждого экземпляра опции Listen и PidFile. Конфиги копируем и поправим только второй:

```
[root@systemd conf]# nano second.conf 
```

```
...
# same ServerRoot for multiple httpd daemons, you will need to change at
# least PidFile.
#
ServerRoot "/etc/httpd"
PidFile /var/run/httpd-second.pid

#
# Listen: Allows you to bind Apache to specific IP addresses and/or
# ports, instead of the default. See also the <VirtualHost>
# directive.
#
# Change this to Listen on specific IP addresses as shown below to 
# prevent Apache from glomming onto all bound IP addresses.
#
#Listen 12.34.56.78:80
Listen 8080

#
# Dynamic Shared Object (DSO) Support
...

^G Get Help	 ^O Write Out     ^W Where Is	   ^K Cut Text      ^J Justify       ^C Cur Pos       M-U Undo         M-A Mark Text    M-] To Bracket   M-▲ Previous     ^B Back
^X Exit          ^R Read File     ^\ Replace	   ^U Uncut Text    ^T To Spell      ^_ Go To Line    M-E Redo         M-6 Copy Text    M-W WhereIs Next M-▼ Next         ^F Forward
```

Запустим сервис httpd:

```
[root@systemd conf]# systemctl start httpd@first
```

```
[root@systemd conf]# systemctl start httpd@second
```

Проверим сервис. Посмотрим какие порты слушаются:

```
[root@systemd conf]# ss -tnulp | grep httpd
```

```
tcp   LISTEN 0      511          0.0.0.0:8080      0.0.0.0:*    users:(("httpd",pid=31122,fd=3),("httpd",pid=31121,fd=3),("httpd",pid=31120,fd=3),("httpd",pid=31118,fd=3))
tcp   LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("httpd",pid=30900,fd=3),("httpd",pid=30899,fd=3),("httpd",pid=30898,fd=3),("httpd",pid=30896,fd=3))
```

Проверим статус служб:

```
[root@systemd ~]# systemctl status httpd@first.service
```

```
● httpd@first.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2024-05-01 17:16:50 UTC; 26s ago
     Docs: man:httpd@.service(8)
  Process: 1078 ExecStartPre=/bin/chown root.apache /run/httpd/instance-first (code=exited, status=0/SUCCESS)
  Process: 1076 ExecStartPre=/bin/mkdir -m 710 -p /run/httpd/instance-first (code=exited, status=0/SUCCESS)
 Main PID: 1080 (httpd)
   Status: "Running, listening on: port 80"
    Tasks: 213 (limit: 4617)
   Memory: 30.1M
   CGroup: /system.slice/system-httpd.slice/httpd@first.service
           ├─1080 /usr/sbin/httpd -DFOREGROUND -f conf/first.conf
           ├─1081 /usr/sbin/httpd -DFOREGROUND -f conf/first.conf
           ├─1082 /usr/sbin/httpd -DFOREGROUND -f conf/first.conf
           ├─1083 /usr/sbin/httpd -DFOREGROUND -f conf/first.conf
           └─1084 /usr/sbin/httpd -DFOREGROUND -f conf/first.conf

May 01 17:16:49 systemd systemd[1]: Starting The Apache HTTP Server...
May 01 17:16:50 systemd httpd[1080]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppres>
May 01 17:16:50 systemd systemd[1]: Started The Apache HTTP Server.
May 01 17:16:50 systemd httpd[1080]: Server configured, listening on: port 80
```

```
[root@systemd ~]# systemctl status httpd@second.service
```

```
● httpd@second.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2024-05-01 17:16:56 UTC; 32s ago
     Docs: man:httpd@.service(8)
  Process: 1300 ExecStartPre=/bin/chown root.apache /run/httpd/instance-second (code=exited, status=0/SUCCESS)
  Process: 1298 ExecStartPre=/bin/mkdir -m 710 -p /run/httpd/instance-second (code=exited, status=0/SUCCESS)
 Main PID: 1302 (httpd)
   Status: "Running, listening on: port 8080"
    Tasks: 213 (limit: 4617)
   Memory: 31.1M
   CGroup: /system.slice/system-httpd.slice/httpd@second.service
           ├─1302 /usr/sbin/httpd -DFOREGROUND -f conf/second.conf
           ├─1303 /usr/sbin/httpd -DFOREGROUND -f conf/second.conf
           ├─1304 /usr/sbin/httpd -DFOREGROUND -f conf/second.conf
           ├─1305 /usr/sbin/httpd -DFOREGROUND -f conf/second.conf
           └─1306 /usr/sbin/httpd -DFOREGROUND -f conf/second.conf

May 01 17:16:56 systemd systemd[1]: Starting The Apache HTTP Server...
May 01 17:16:56 systemd httpd[1302]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppres>
May 01 17:16:56 systemd systemd[1]: Started The Apache HTTP Server.
May 01 17:16:56 systemd httpd[1302]: Server configured, listening on: port 8080
```



### **Настройка автоматизации в Ansible** ###

Для автоматического развёртывания ВМ со всеми вышеперечисленными настройками буду использовать Ansible. 
Вся структура плейбука и все файлы, используемые при развёртывании, находятся в репозитории.
Для удобства развёртывания пишу bash-скрипт start.sh.
После успешного развёртывания ВМ провожу проверки работы сервисов, описанные выше.



Результат: полностью рабочая ВМ с заданными характеристиками.

Задание выполнено.






































































































































































































































