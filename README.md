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






















































































































































