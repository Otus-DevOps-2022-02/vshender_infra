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
- Configured access to the `bastion` and `someinternalhost` VMs by aliases.
- Configured access to `someinternalhost` via VPN (based on [Pritunl](https://pritunl.com/)).
- Configured a SSL certificate.


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

Contents of the `.ssh/config` file for accessing the VMs using aliases:
```
Host bastion
    Hostname 51.250.77.242
    User appuser
    IdentityFile ~/.ssh/appuser
Host someinternalhost
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyCommand ssh -q bastion nc -q0 10.128.0.19 22
```

or
```
Host bastion
    Hostname 51.250.77.242
    User appuser
    IdentityFile ~/.ssh/appuser
Host someinternalhost
    Hostname 10.128.0.19
    User appuser
    ProxyJump bastion
```

Install and setup `pritunl` on the `bastion` VM:
```
$ scp VPN/setupvpn.sh bastion:/home/appuser
setupvpn.sh

$ ssh bastion
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.4.0-117-generic x86_64)
...

appuser@bastion:~$ sudo bash setupvpn.sh
...

appuser@bastion:~$ # open in browser http://51.250.77.242/setup

appuser@bastion:~$ sudo pritunl setup-key
...

appuser@bastion:~$ sudo pritunl default-password
Administrator default password:
  username: "pritunl"
  password: "..."
```

Pritunl user:
- username: test
- PIN: 6214157507237678334670591556762

See [Connecting to a Pritunl vpn server](https://docs.pritunl.com/docs/connecting) for instructions.

To setup Let's Encrypt for Pritunl admin panel just enter "51-250-77-242.sslip.io" in "Settings -> Lets Encrypt Domain".


## Homework #6: play-travis

- Installed and configured the `yc` CLI utility.
- Created a VM for the application.
- Added the application deployment scripts.
- Added a metadata file that deploys the application on VM instance creation.


Related Yandex Cloud documentation:

- [Install CLI](https://cloud.yandex.ru/docs/cli/operations/install-cli)
- [Profile Create](https://cloud.yandex.ru/docs/cli/operations/profile/profile-create)

Create a Yandex Cloud profile:
```
$ yc init
Welcome! This command will take you through the configuration process.
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=... in order to obtain OAuth token.

Please enter OAuth token: ...
You have one cloud available: 'otus-vadimshendergmailcom' (id = ...). It is going to be used by default.
Please choose folder to use:
 [1] default (id = ...)
 [2] infra (id = ...)
 [3] Create a new folder
Please enter your numeric choice: 2
Your current folder has been set to 'default' (id = ...).
Do you want to configure a default Compute zone? [Y/n] y
Which zone do you want to use as a profile default?
 [1] ru-central1-a
 [2] ru-central1-b
 [3] ru-central1-c
 [4] Don't set default zone
Please enter your numeric choice: 1
Your profile default Compute zone has been set to 'ru-central1-a'.
```

Check `yc` configuration:
```
$ yc config list
token: ...
cloud-id: ...
folder-id: ...
compute-default-zone: ru-central1-a

$ yc config profile list
default ACTIVE
```

Create a new VM instance:
```
$ yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --ssh-key ~/.ssh/appuser.pub
...

$ yc compute instance list
+----------------------+------------+---------------+---------+--------------+-------------+
|          ID          |    NAME    |    ZONE ID    | STATUS  | EXTERNAL IP  | INTERNAL IP |
+----------------------+------------+---------------+---------+--------------+-------------+
| fhmphnrc1ifveo9k059k | reddit-app | ru-central1-a | RUNNING | 51.250.94.42 | 10.128.0.17 |
+----------------------+------------+---------------+---------+--------------+-------------+
```

The created host's IP address and the port for the application:
```
testapp_IP = 51.250.94.42
testapp_port = 9292
```

Install the required dependencies and deploy the application:
```
$ scp config-scripts/*.sh yc-user@51.250.94.42:/home/yc-user
...

$ ssh yc-user@51.250.94.42
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)
...

yc-user@reddit-app:~$ ./install_ruby.sh
...

yc-user@reddit-app:~$ ruby -v
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]

yc-user@reddit-app:~$ bundler -v
Bundler version 1.11.2

yc-user@reddit-app:~$ ./install_mongodb.sh
...

yc-user@reddit-app:~$ sudo systemctl status mongod
● mongod.service - MongoDB Database Server
   Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-06-19 18:24:46 UTC; 15s ago
...

yc-user@reddit-app:~$ ./deploy.sh
...
```

Create a new VM instance providing the metadata that deploys the application:
```
$ yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --metadata-from-file user-data=config-scripts/metadata.yaml
...
```


## Homework #7: packer-base

- Created and configured a Yandex Cloud service account.
- Added a packer template for the base image.
- Parameterized the packer template for the base image.


Create a Yandex Cloud service account for Packer:
```
$ SVC_ACCOUNT=svc

$ FOLDER_ID=$(yc config list | grep ^folder-id | awk '{ print $2 }')

$ yc iam service-account create --name $SVC_ACCOUNT --folder-id $FOLDER_ID
id: ajegsts7f3h7al6lnfti
folder_id: b1go0bbc4eormvjuv1mq
created_at: "2022-06-20T12:42:42.422216212Z"
name: svc
```

Grant the created service account access to the folder:
```
$ ACCOUNT_ID=$(yc iam service-account get $SVC_ACCOUNT | grep ^id | awk '{ print $2 }')

$ yc resource-manager folder add-access-binding --id $FOLDER_ID \
    --role editor \
    --service-account-id $ACCOUNT_ID
done (1s)
```

Generate an IAM key and save it to a file:
```
$ yc iam key create --service-account-id $ACCOUNT_ID --output yc-svc-key.json
id: ajeqipnvev31urbod1dv
service_account_id: ajeg1tbs3ho02l5u4tg0
created_at: "2021-07-13T09:56:23.667310740Z"
key_algorithm: RSA_2048
```

Build a base image for the application:
```
$ cd packer

$ packer validate ./ubuntu16.json
The configuration is valid.

$ packer build ./ubuntu16.json
yandex: output will be in this color.

==> yandex: Creating temporary RSA SSH key for instance...
==> yandex: Using as source image: fd8icj5tthu0acqb2vau (name: "ubuntu-16-04-lts-v20220620", family: "ubuntu-1604-lts")
==> yandex: Creating network...
==> yandex: Creating subnet in zone "ru-central1-a"...
==> yandex: Creating disk...
==> yandex: Creating instance...
==> yandex: Waiting for instance with id fhmfuumug63jem1pevmd to become active...
    yandex: Detected instance IP: 51.250.90.119
==> yandex: Using SSH communicator to connect: 51.250.90.119
==> yandex: Waiting for SSH to become available...
==> yandex: Connected to SSH!
==> yandex: Provisioning with shell script: scripts/install_ruby.sh
...
==> yandex: Stopping instance...
==> yandex: Deleting instance...
    yandex: Instance has been deleted!
==> yandex: Creating image: reddit-base-1655732400
==> yandex: Waiting for image to complete...
==> yandex: Success image create...
==> yandex: Destroying subnet...
    yandex: Subnet has been deleted!
==> yandex: Destroying network...
    yandex: Network has been deleted!
==> yandex: Destroying boot disk...
    yandex: Disk has been deleted!
Build 'yandex' finished after 3 minutes 22 seconds.

==> Wait completed after 3 minutes 22 seconds

==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-base-1655732400 (id: fd87q6i0re98bj8v6fgc) with family name reddit-base

$ yc compute image list
+----------------------+------------------------+-------------+----------------------+--------+
|          ID          |          NAME          |   FAMILY    |     PRODUCT IDS      | STATUS |
+----------------------+------------------------+-------------+----------------------+--------+
| fd87q6i0re98bj8v6fgc | reddit-base-1655732400 | reddit-base | f2ej52ijfor6n4fg5v0f | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```

Build a base image for the application using the parameterized template:
```
$ packer validate -var-file=variables.json ./ubuntu16.json
The configuration is valid.

$ packer build -var-file=variables.json ./ubuntu16.json
...
```
