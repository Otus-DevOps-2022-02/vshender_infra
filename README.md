# vshender_infra

vshender Infra repository


## Homework #4: play-travis

- Added a pre-commit hook.
- Added a Github PR template.
- Enabled the Slack integration.
- Added Github actions.
- Fixed the Python test.

<details><summary>Details</summary>

Install a pre-commit hook:
```
$ vim .pre-commit-config.yaml
$ pre-commit install
```

Subscribe a Slack channel to a Github repository:
```
/github subscribe Otus-DevOps-2022-02/vshender_infra commits:all
```

</details>


## Homework #5: cloud-bastion

- Created a Yandex Cloud account.
- Gererated new SSH keys.
- Created two VMs (`bastion` and `someinternalhost`).
- Configured access to the `bastion` and `someinternalhost` VMs by aliases.
- Configured access to `someinternalhost` via VPN (based on [Pritunl](https://pritunl.com/)).
- Configured a SSL certificate.

<details><summary>Details</summary>

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

</details>


## Homework #6: play-travis

- Installed and configured the `yc` CLI utility.
- Created a VM for the application.
- Added the application deployment scripts.
- Added a metadata file that deploys the application on VM instance creation.

<details><summary>Details</summary>

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

</details>


## Homework #7: packer-base

- Created and configured a Yandex Cloud service account.
- Added a packer template for the base image.
- Parameterized the packer template for the base image.
- Added a packer template for the application image.

<details><summary>Details</summary>

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

Build the application image:
```
$ packer validate -var-file=variables.json ./immutable.json
The configuration is valid.

$ packer build -var-file=variables.json ./immutable.json
...
```

Create a VM instance using the application image:
```
$ ../config-scripts/create-reddit-vm.sh
...
```

</details>


## Homework #8: terraform-1

- Created a VM instance using Terraform.
- Added an output variable for an external IP address.
- Added provisioners for the application deployment.
- Used input variables for the infrastructure configuration.
- Created a network load balancer.

<details><summary>Details</summary>

[Yandex.Cloud provider documentation](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs)

Get a config for Yandex provider:
```
$ yc config list
token: ...
cloud-id: ...
folder-id: ...
compute-default-zone: ru-central1-a
```

Initialize provider plugins:
```
$ cd terraform

$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching "0.73.0"...
- Installing yandex-cloud/yandex v0.73.0...
- Installed yandex-cloud/yandex v0.73.0 (self-signed, key ID E40F590B50BB8E40)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Get an ID of the base image for the application:
```
$ yc compute image list
+----------------------+------------------------+-------------+----------------------+--------+
|          ID          |          NAME          |   FAMILY    |     PRODUCT IDS      | STATUS |
+----------------------+------------------------+-------------+----------------------+--------+
| fd87q6i0re98bj8v6fgc | reddit-base-1655732400 | reddit-base | f2ej52ijfor6n4fg5v0f | READY  |
| fd89dv82hadttcirp1hr | reddit-base-1655736298 | reddit-base | f2ej52ijfor6n4fg5v0f | READY  |
| fd8a5el5f41qgp5qjd8p | reddit-full-1655742289 | reddit-full | f2ej52ijfor6n4fg5v0f | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```

Get an ID of the "default-ru-central1-a" subnet:
```
$ yc vpc subnet list
+----------------------+-----------------------+----------------------+----------------+---------------+-----------------+
|          ID          |         NAME          |      NETWORK ID      | ROUTE TABLE ID |     ZONE      |      RANGE      |
+----------------------+-----------------------+----------------------+----------------+---------------+-----------------+
| b0cjh09a0p3tjffp9fbv | default-ru-central1-c | enpr8orbifbf56p068oa |                | ru-central1-c | [10.130.0.0/24] |
| e2l0jp5kvb00tqjmh9r1 | default-ru-central1-b | enpr8orbifbf56p068oa |                | ru-central1-b | [10.129.0.0/24] |
| e9bqom95bd1o3fkemarr | default-ru-central1-a | enpr8orbifbf56p068oa |                | ru-central1-a | [10.128.0.0/24] |
+----------------------+-----------------------+----------------------+----------------+---------------+-----------------+
```

See an execution plan showing what actions Terraform would take to apply the current configuration:
```
$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.app will be created
  + resource "yandex_compute_instance" "app" {
    ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.

────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

Create a VM instance using Terraform:
```
$ terraform apply -auto-approve

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.app will be created
  + resource "yandex_compute_instance" "app" {
    ...
  }

Plan: 1 to add, 0 to change, 0 to destroy.
yandex_compute_instance.app: Creating...
yandex_compute_instance.app: Still creating... [10s elapsed]
yandex_compute_instance.app: Still creating... [20s elapsed]
yandex_compute_instance.app: Still creating... [30s elapsed]
yandex_compute_instance.app: Still creating... [40s elapsed]
yandex_compute_instance.app: Creation complete after 44s [id=fhmoaa6p1qnl32fg26t6]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

$ ls
main.tf                  terraform.tfstate        terraform.tfstate.backup
```

Get an external IP address of the created VM using the `terraform show` command:
```
$ terraform show | grep nat_ip_address
          nat_ip_address = "51.250.81.64"
```

Connect to the created VM:
```
$ ssh -i ~/.ssh/appuser ubuntu@51.250.81.64
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
ubuntu@fhmoaa6p1qnl32fg26t6: exit
logout
Connection to 51.250.81.64 closed.
```

Add the `external_ip_address_app` output variable and refresh the state:
```
$ terraform refresh
yandex_compute_instance.app: Refreshing state... [id=fhmoaa6p1qnl32fg26t6]

Outputs:

external_ip_address_app = "51.250.81.64"

$ terraform output
external_ip_address_app = "51.250.81.64"

$ terraform output external_ip_address_app
"51.250.81.64"
```

Add [provisioners](https://www.terraform.io/language/resources/provisioners/syntax) for the application deployment and recreate the VM:
```
$ terraform taint yandex_compute_instance.app
Resource instance yandex_compute_instance.app has been marked as tainted.

$ terraform plan
yandex_compute_instance.app: Refreshing state... [id=fhmoaa6p1qnl32fg26t6]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # yandex_compute_instance.app is tainted, so must be replaced
-/+ resource "yandex_compute_instance" "app" {
    ...
    }

Plan: 1 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  ~ external_ip_address_app = "51.250.81.64" -> (known after apply)

────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

$ terraform apply -auto-approve
yandex_compute_instance.app: Refreshing state... [id=fhm3671dtvicqjp0lj67]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # yandex_compute_instance.app is tainted, so must be replaced
-/+ resource "yandex_compute_instance" "app" {
      ...
    }

Plan: 1 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  ~ external_ip_address_app = "51.250.81.64" -> (known after apply)
yandex_compute_instance.app: Destroying... [id=fhm3671dtvicqjp0lj67]
yandex_compute_instance.app: Still destroying... [id=fhm3671dtvicqjp0lj67, 10s elapsed]
yandex_compute_instance.app: Destruction complete after 14s
yandex_compute_instance.app: Creating...
...
yandex_compute_instance.app: Still creating... [1m10s elapsed]
yandex_compute_instance.app: Provisioning with 'remote-exec'...
yandex_compute_instance.app (remote-exec): Connecting to remote host via SSH...
yandex_compute_instance.app (remote-exec):   Host: 51.250.80.242
yandex_compute_instance.app (remote-exec):   User: ubuntu
yandex_compute_instance.app (remote-exec):   Password: false
yandex_compute_instance.app (remote-exec):   Private key: true
yandex_compute_instance.app (remote-exec):   Certificate: false
yandex_compute_instance.app (remote-exec):   SSH Agent: false
yandex_compute_instance.app (remote-exec):   Checking Host Key: false
yandex_compute_instance.app (remote-exec):   Target Platform: unix
yandex_compute_instance.app (remote-exec): Connected!
yandex_compute_instance.app: Still creating... [1m20s elapsed]
yandex_compute_instance.app (remote-exec): Reading package lists... 0%
...
yandex_compute_instance.app (remote-exec): Bundle complete! 11 Gemfile dependencies, 24 gems now installed.
yandex_compute_instance.app (remote-exec): Use `bundle show [gemname]` to see where a bundled gem is installed
yandex_compute_instance.app (remote-exec): Post-install message from capistrano3-puma:

yandex_compute_instance.app (remote-exec):     All plugins need to be explicitly installed with install_plugin.
yandex_compute_instance.app (remote-exec):     Please see README.md
yandex_compute_instance.app (remote-exec):   Created symlink from /etc/systemd/system/multi-user.target.wants/puma.service to /etc/systemd/system/puma.service.
yandex_compute_instance.app: Creation complete after 1m53s [id=fhmjhk18bf9n5et3lrd2]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

external_ip_address_app = "51.250.80.242"
```

Open http://51.250.80.242:9292/ and check the application.

Use input variables for the infrastructure configuration and recreate the VM:
```
$ terraform destroy -auto-approve
yandex_compute_instance.app: Refreshing state... [id=fhmjhk18bf9n5et3lrd2]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # yandex_compute_instance.app will be destroyed
  - resource "yandex_compute_instance" "app" {
    ...
    }

Plan: 0 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  - external_ip_address_app = "51.250.80.242" -> null
yandex_compute_instance.app: Destroying... [id=fhmjhk18bf9n5et3lrd2]
yandex_compute_instance.app: Still destroying... [id=fhmjhk18bf9n5et3lrd2, 10s elapsed]
yandex_compute_instance.app: Destruction complete after 14s

Destroy complete! Resources: 1 destroyed.

$ terraform apply -auto-approve
...
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.94.229"
```

Create a network load balancer (see [yandex_lb_network_load_balancer](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_network_load_balancer) and [yandex_lb_target_group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_target_group)):
```
$ terraform apply -auto-approve
...
yandex_lb_target_group.app_lb_target_group: Creating...
yandex_lb_target_group.app_lb_target_group: Creation complete after 3s [id=enp6b9l8trdd86k50f7s]
yandex_lb_network_load_balancer.app_lb: Creating...
yandex_lb_network_load_balancer.app_lb: Creation complete after 3s [id=enpprkh4ar833qsmts6d]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.94.229"
lb_ip_address = "51.250.93.157"
```

Open http://51.250.93.157/ and check the application.

</details>
