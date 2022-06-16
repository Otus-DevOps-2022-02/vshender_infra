# vshender_infra

vshender Infra repository


## Homework #4: play-travis

- Added a pre-commit hook.
- Added a Github PR template.
- Enabled the Slack integration.
- Added Github actions.
- Fixed the Python test.


Install a pre-commit hook:
```
$ vim .pre-commit-config.yaml
$ pre-commit install
```

Subscribe a Slack channel to a Github repository:
```
/github subscribe Otus-DevOps-2022-02/vshender_infra commits:all
```


## Homework #5: cloud-bastion

- Created a Yandex Cloud account.
- Gererated new SSH keys.
- Created two VMs (`bastion` and `someinternalhost`).


Generate SSH authentication keys:
```
$ ssh-keygen -t rsa -f ~/.ssh/appuser -C appuser -P ""
Generating public/private rsa key pair.
Your identification has been saved in /Users/vshender/.ssh/appuser
Your public key has been saved in /Users/vshender/.ssh/appuser.pub
...
```

Host IP addresses:
```
bastion_IP = 51.250.77.242
someinternalhost_IP = 10.128.0.19
```

Connect to the `bastion` VM:
```
$ ssh -i ~/.ssh/appuser appuser@51.250.77.242
...
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.4.0-117-generic x86_64)
...
appuser@bastion:~$
```

Connect to the `someinternalhost` VM via `bastion` using SSH agent forwarding:
```
$ ssh-add -L
The agent has no identities.

$ ssh-add ~/.ssh/appuser
Identity added: /Users/vshender/.ssh/appuser (appuser)

$ ssh -A appuser@51.250.77.242
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.4.0-117-generic x86_64)
...

appuser@bastion:~$ ssh 10.128.0.19
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.4.0-117-generic x86_64)
...

appuser@someinternalhost:~$ ip a show eth0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether d0:0d:1f:62:a8:7f brd ff:ff:ff:ff:ff:ff
    inet 10.128.0.19/24 brd 10.128.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::d20d:1fff:fe62:a87f/64 scope link
       valid_lft forever preferred_lft forever
```

Connect to the `someinternalhost` VM via `bastion` using a single command:
```
$ ssh -A -t appuser@51.250.77.242 ssh 10.128.0.19
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.4.0-117-generic x86_64)
...
appuser@someinternalhost:~$
```

or
```
$ ssh -J appuser@51.250.77.242 appuser@10.128.0.19
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.4.0-117-generic x86_64)
...
appuser@someinternalhost:~$
```

Useful links:
- [SSH Agent Explained](https://smallstep.com/blog/ssh-agent-explained/)
- [SSH to remote hosts through a proxy or bastion with ProxyJump](https://www.redhat.com/sysadmin/ssh-proxy-bastion-proxyjump)
