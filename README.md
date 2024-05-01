# ****Systemd - создание unit-файла**** #

### Описание домашннего задания ###

Выполнить следующие задания и подготовить развёртывание результата выполнения с использованием Vagrant и Vagrant shell provisioner:
- Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig или в /etc/default).
- Установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).
- Дополнить unit-файл httpd (он же apache2) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.

### **Выполнение** ###

Задание выполняется на рабочей станции с ОС Ubuntu 22.04.4 LTS с заранее установленными Vagrant 2.4.1 и VirtualBox 7.0. 
Перед выполнением предварительно подготовлен репозиторий <https://github.com/ConstantaNF/systemd.git>

### **Подготовка окружения** ###

Для развёртывания управляемой ВМ посредством Vagrant создаю Vagrantfile и скрипт для установки необходимых пакетов через `provision`. Cоздаю их в заранее подготовленном каталоге 
`/home/adminkonstantin/systemd`.

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
WORD="error"
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
[root@systemd log]# cat dnf.log > watchlog.log
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






























































































































































