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
??? mongod.service - MongoDB Database Server
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
- Created a second VM instance.
- Created two VM instances using the `count` parameter.

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

????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

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

????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

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

Create a second VM instance:
```
$ terraform plan
yandex_compute_instance.app: Refreshing state... [id=fhmpgq0sqconiuha2fap]
yandex_lb_target_group.app_lb_target_group: Refreshing state... [id=enp6b9l8trdd86k50f7s]
yandex_lb_network_load_balancer.app_lb: Refreshing state... [id=enpprkh4ar833qsmts6d]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
  ~ update in-place

Terraform will perform the following actions:

  # yandex_compute_instance.app2 will be created
  + resource "yandex_compute_instance" "app2" {
    ...
    }

  # yandex_lb_target_group.app_lb_target_group will be updated in-place
  ~ resource "yandex_lb_target_group" "app_lb_target_group" {
        id         = "enp6b9l8trdd86k50f7s"
        name       = "app-lb-target-group"
        # (4 unchanged attributes hidden)

      + target {
          + address   = (known after apply)
          + subnet_id = "e9bqom95bd1o3fkemarr"
        }
        # (1 unchanged block hidden)
    }

Plan: 1 to add, 1 to change, 0 to destroy.

Changes to Outputs:
  + external_ip_address_app2 = (known after apply)

????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

$ terraform apply -auto-approve
...
Apply complete! Resources: 1 added, 1 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.94.229"
external_ip_address_app2 = "51.250.86.134"
lb_ip_address = "51.250.93.157"
```

Use the `count` parameter to create VM instances for the application (see [dynamic Blocks](https://www.terraform.io/language/expressions/dynamic-blocks)):
```
$ terraform destroy -auto-approve
...

$ terraform apply -auto-approve
yandex_compute_instance.app2: Refreshing state... [id=fhmvsvpegjoi2gtp2hn7]
yandex_compute_instance.app[0]: Refreshing state... [id=fhm2vdlaapl6uv7ieidt]
yandex_lb_target_group.app_lb_target_group: Refreshing state... [id=enp8gjo7a0lvnsl8cecg]
yandex_lb_network_load_balancer.app_lb: Refreshing state... [id=enp5n1474kt4s6flf84e]

Note: Objects have changed outside of Terraform
...
Plan: 1 to add, 2 to change, 1 to destroy.

Changes to Outputs:
  ~ external_ip_address_app  = "51.250.94.61" -> [
      + "51.250.94.61",
      + (known after apply),
    ]
  - external_ip_address_app2 = "51.250.69.6" -> null
yandex_compute_instance.app2: Destroying... [id=fhmvsvpegjoi2gtp2hn7]
yandex_compute_instance.app[1]: Creating...
yandex_compute_instance.app[0]: Modifying... [id=fhm2vdlaapl6uv7ieidt]
yandex_compute_instance.app[0]: Modifications complete after 6s [id=fhm2vdlaapl6uv7ieidt]
yandex_compute_instance.app2: Still destroying... [id=fhmvsvpegjoi2gtp2hn7, 10s elapsed]
yandex_compute_instance.app[1]: Still creating... [10s elapsed]
yandex_compute_instance.app2: Destruction complete after 14s
yandex_compute_instance.app[1]: Still creating... [20s elapsed]
...
yandex_compute_instance.app[1] (remote-exec):     All plugins need to be explicitly installed with install_plugin.
yandex_compute_instance.app[1] (remote-exec):     Please see README.md
yandex_compute_instance.app[1] (remote-exec):   Created symlink from /etc/systemd/system/multi-user.target.wants/puma.service to /etc/systemd/system/puma.service.
yandex_compute_instance.app[1]: Creation complete after 1m38s [id=fhmrureeugrl0dmeqpbo]
yandex_lb_target_group.app_lb_target_group: Modifying... [id=enp8gjo7a0lvnsl8cecg]
yandex_lb_target_group.app_lb_target_group: Modifications complete after 2s [id=enp8gjo7a0lvnsl8cecg]

Apply complete! Resources: 1 added, 2 changed, 1 destroyed.

Outputs:

external_ip_address_app = [
  "51.250.94.61",
  "51.250.94.171",
]
lb_ip_address = "51.250.76.174"
```

</details>


## Homework #9: terraform-2

- Created the separate network for the application VM instance.
- Created base images for the DB and the application.
- Created separate VM instances for the DB and the application.
- Refactored the infrastructure definition using modules.
- Created the `prod` and `stage` infrastructures.
- Used the "s3" backend to store Terraform state in an object bucket.
- Implemented the VM provisioners disabling.

<details><summary>Details</summary>

Create a separate network for the app VM instance:
```
$ cd terraform

$ terraform destroy -auto-approve
...
yandex_lb_network_load_balancer.app_lb: Destroying... [id=enp5n1474kt4s6flf84e]
yandex_lb_network_load_balancer.app_lb: Destruction complete after 4s
yandex_lb_target_group.app_lb_target_group: Destroying... [id=enp8gjo7a0lvnsl8cecg]
yandex_lb_target_group.app_lb_target_group: Destruction complete after 2s
yandex_compute_instance.app[0]: Destroying... [id=fhm2vdlaapl6uv7ieidt]
yandex_compute_instance.app[1]: Destroying... [id=fhmrureeugrl0dmeqpbo]
yandex_compute_instance.app[1]: Still destroying... [id=fhmrureeugrl0dmeqpbo, 10s elapsed]
yandex_compute_instance.app[0]: Still destroying... [id=fhm2vdlaapl6uv7ieidt, 10s elapsed]
yandex_compute_instance.app[1]: Destruction complete after 12s
yandex_compute_instance.app[0]: Destruction complete after 12s

Destroy complete! Resources: 4 destroyed.

$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:
  # yandex_compute_instance.app[0] will be created
  + resource "yandex_compute_instance" "app" {
      ...
    }
  # yandex_vpc_network.app_network will be created
  + resource "yandex_vpc_network" "app_network" {
      ...
    }
  # yandex_vpc_subnet.app_subnet will be created
  + resource "yandex_vpc_subnet" "app_subnet" {
      ...
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + external_ip_address_app = [
      + (known after apply),
    ]

????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

$ terraform apply -auto-approve
...
yandex_vpc_network.app_network: Creating...
yandex_vpc_network.app_network: Creation complete after 3s [id=enph5srrts10kq9h6q46]
yandex_vpc_subnet.app_subnet: Creating...
yandex_vpc_subnet.app_subnet: Creation complete after 1s [id=e9bnii4nqtv6vmejigus]
yandex_compute_instance.app[0]: Creating...
...
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = [
  "51.250.12.47",
]

$ terraform destroy -auto-approve
...
Destroy complete! Resources: 3 destroyed.
```

Create base images for the DB and the application:
```
$ cd ../packer

$ packer build -var-file=variables.json ./db.json
...
==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-db-base-1655933993 (id: fd8bvuaat05ogds90rte) with family name reddit-db-base

$ packer build -var-file=variables.json ./app.json
...
==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-app-base-1655934193 (id: fd84km3m351crgj9upkq) with family name reddit-app-base

$ yc compute image list
+----------------------+----------------------------+-----------------+----------------------+--------+
|          ID          |            NAME            |     FAMILY      |     PRODUCT IDS      | STATUS |
+----------------------+----------------------------+-----------------+----------------------+--------+
| fd84km3m351crgj9upkq | reddit-app-base-1655934193 | reddit-app-base | f2ej52ijfor6n4fg5v0f | READY  |
| fd87q6i0re98bj8v6fgc | reddit-base-1655732400     | reddit-base     | f2ej52ijfor6n4fg5v0f | READY  |
| fd89dv82hadttcirp1hr | reddit-base-1655736298     | reddit-base     | f2ej52ijfor6n4fg5v0f | READY  |
| fd8a5el5f41qgp5qjd8p | reddit-full-1655742289     | reddit-full     | f2ej52ijfor6n4fg5v0f | READY  |
| fd8bvuaat05ogds90rte | reddit-db-base-1655933993  | reddit-db-base  | f2ej52ijfor6n4fg5v0f | READY  |
+----------------------+----------------------------+-----------------+----------------------+--------+
```

Create separate VM instances for DB and the application:
```
$ terraform init -upgrade

Initializing the backend...

Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching "0.73.0"...
- Finding latest version of hashicorp/null...
- Using previously-installed yandex-cloud/yandex v0.73.0
- Installing hashicorp/null v3.1.1...
- Installed hashicorp/null v3.1.1 (signed by HashiCorp)

...

$ terraform apply -auto-approve
...
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.87.139"
external_ip_address_db = "51.250.65.74"
```

Open http://51.250.87.139:9292/ and check the application.

Destroy the infrastructure:
```
$ terraform destroy -auto-approve
...
Destroy complete! Resources: 6 destroyed.
```

Install the `app`, `db`, and `vpc` modules.
```
$ terraform get
- app in modules/app
- db in modules/db
- vpc in modules/vpc

$ tree .terraform
.terraform
????????? modules
???   ????????? modules.json
????????? providers
    ????????? registry.terraform.io
        ????????? hashicorp
        ???   ????????? null
        ???       ????????? 3.1.1
        ???           ????????? darwin_amd64
        ???               ????????? terraform-provider-null_v3.1.1_x5
        ????????? yandex-cloud
            ????????? yandex
                ????????? 0.73.0
                    ????????? darwin_amd64
                        ????????? CHANGELOG.md
                        ????????? LICENSE
                        ????????? README.md
                        ????????? terraform-provider-yandex_v0.73.0

11 directories, 6 files

$ cat .terraform/modules/modules.json | jq
{
  "Modules": [
    {
      "Key": "db",
      "Source": "./modules/db",
      "Dir": "modules/db"
    },
    {
      "Key": "vpc",
      "Source": "./modules/vpc",
      "Dir": "modules/vpc"
    },
    {
      "Key": "",
      "Source": "",
      "Dir": "."
    },
    {
      "Key": "app",
      "Source": "./modules/app",
      "Dir": "modules/app"
    }
  ]
}

$ terraform init -upgrade
Upgrading modules...
- app in modules/app
- db in modules/db
- vpc in modules/vpc

Initializing the backend...

Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching "~> 0.73.0"...
- Finding latest version of hashicorp/null...
- Using previously-installed yandex-cloud/yandex v0.73.0
- Using previously-installed hashicorp/null v3.1.1
...
```

```
$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.app.null_resource.app_provisioning will be created
  + resource "null_resource" "app_provisioning" {
    ...
  }

  # module.app.yandex_compute_instance.app will be created
  + resource "yandex_compute_instance" "app" {
    ...
  }

  # module.db.null_resource.db_provisioning will be created
  + resource "null_resource" "db_provisioning" {
    ...
  }

  # module.db.yandex_compute_instance.db will be created
  + resource "yandex_compute_instance" "db" {
    ...
  }

  # module.vpc.yandex_vpc_network.app_network will be created
  + resource "yandex_vpc_network" "app_network" {
    ...
  }

  # module.vpc.yandex_vpc_subnet.app_subnet will be created
  + resource "yandex_vpc_subnet" "app_subnet" {
    ...
  }

Plan: 6 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + external_ip_address_app = (known after apply)
  + external_ip_address_db  = (known after apply)

????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

$ terraform apply -auto-approve
...

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.91.238"
external_ip_address_db = "51.250.71.69"
```

Destroy the infrastructure:
```
$ terraform destroy -auto-approve
...
Destroy complete! Resources: 6 destroyed.
```

Check the `prod` infrastructure:
```
$ cd prod

$ terraform init
Initializing modules...
- app in ../modules/app
- db in ../modules/db
- vpc in ../modules/vpc

Initializing the backend...

Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching "~> 0.73.0"...
- Finding latest version of hashicorp/null...
- Installing hashicorp/null v3.1.1...
- Installed hashicorp/null v3.1.1 (signed by HashiCorp)
- Installing yandex-cloud/yandex v0.73.0...
- Installed yandex-cloud/yandex v0.73.0 (self-signed, key ID E40F590B50BB8E40)
...

$ terraform apply -auto-approve
...

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.94.145"
external_ip_address_db = "51.250.69.6"

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 6 destroyed.
```

Check the `stage` infrastructure:
```
$ cd ../stage

$ terraform init
Initializing modules...
- app in ../modules/app
- db in ../modules/db
- vpc in ../modules/vpc

Initializing the backend...

Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching "~> 0.73.0"...
- Finding latest version of hashicorp/null...
- Installing yandex-cloud/yandex v0.73.0...
- Installed yandex-cloud/yandex v0.73.0 (self-signed, key ID E40F590B50BB8E40)
- Installing hashicorp/null v3.1.1...
- Installed hashicorp/null v3.1.1 (signed by HashiCorp)
...

$ terraform apply -auto-approve
...

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.68.153"
external_ip_address_db = "51.250.93.213"

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 6 destroyed.

$ cd ..
```

Create a bucket for Terraform state storage:
```
$ terraform init
...

$ terraform apply -auto-approve
...
Plan: 2 to add, 0 to change, 0 to destroy.
yandex_iam_service_account_static_access_key.sa_static_key: Creating...
yandex_iam_service_account_static_access_key.sa_static_key: Creation complete after 2s [id=aje1h800b2gkr2583o01]
yandex_storage_bucket.tfstate_storage: Creating...
yandex_storage_bucket.tfstate_storage: Creation complete after 2s [id=otus-tfstate-storage]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Configure the `aws` CLI tool (obtain info about access key from the Terraform state):
```
$ aws configure
AWS Access Key ID [None]: YC*********************4c
AWS Secret Access Key [None]: YC************************************FP
Default region name [None]:
Default output format [None]:

$ aws --endpoint-url=https://storage.yandexcloud.net s3 ls --recursive s3://otus-vshender-tfstate-storage

```

Create `prod` and `stage` infrastructures saving Terraform state in the object bucket:
```
$ cd prod

$ rm -if terraform.tfstate terraform.tfstate.backup

$ terraform init
Initializing modules...

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Reusing previous version of yandex-cloud/yandex from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Using previously-installed yandex-cloud/yandex v0.73.0
- Using previously-installed hashicorp/null v3.1.1

Terraform has been successfully initialized!
...

$ terraform apply -auto-approve
...
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.80.174"
external_ip_address_db = "51.250.87.241"

$ terraform destroy -auto-approve
...
Destroy complete! Resources: 6 destroyed.

$ aws --endpoint-url=https://storage.yandexcloud.net s3 ls --recursive s3://otus-vshender-tfstate-storage
2022-06-26 14:33:50      11464 prod/terraform.tfstate

$ cd ../stage

$ rm -if terraform.tfstate terraform.tfstate.backup

$ terraform init
Initializing modules...

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Reusing previous version of yandex-cloud/yandex from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Using previously-installed hashicorp/null v3.1.1
- Using previously-installed yandex-cloud/yandex v0.73.0

Terraform has been successfully initialized!
...

$ terraform apply -auto-approve
...
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.77.166"
external_ip_address_db = "51.250.89.233"

$ terraform destroy -auto-approve
...
Destroy complete! Resources: 6 destroyed.

$ aws --endpoint-url=https://storage.yandexcloud.net s3 ls --recursive s3://otus-vshender-tfstate-storage
2022-06-26 14:36:02        155 prod/terraform.tfstate
2022-06-26 14:41:53        155 stage/terraform.tfstate

$ cd ..
```

</details>


## Homework #10: ansible-1

- Installed Ansible.
- Created the `stage` infrastructure.
- Added an inventory file.
- Configured Ansible using the `ansible.cfg` file.
- Added host groups.
- Added a YAML inventory file.
- Checked that the servers' components are installed.
- Cloned the application repository to the app server.
- Added the application cloning playbook.
- Implemented an inventory file generation.
- Added a dynamic inventory.

<details><summary>Details</summary>

Install Ansible:
```
$ cd ansible
$ pip install -r requirements.txt
...
Successfully installed ansible-6.0.0
```

Create a staging environment:
```
$ cd ../terraform

$ terraform apply -auto-approve
...
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

$ cd stage

$ terraform apply -auto-approve
...
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.89.224"
external_ip_address_db = "51.250.95.242"

$ cd ../../ansible
```

Check the inventory file:
```
$ ansible appserver -i ./inventory -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}

$ ansible dbserver -i ./inventory -m ping
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Check the configuration from the `ansible.cfg` file:
```
$ ansible appserver -m command -a uptime
appserver | CHANGED | rc=0 >>
 14:26:37 up 11 min,  1 user,  load average: 0.00, 0.02, 0.03

$ ansible dbserver -m command -a uptime
dbserver | CHANGED | rc=0 >>
 14:26:57 up 11 min,  1 user,  load average: 0.08, 0.02, 0.01
```

Check the host group:
```
$ ansible app -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Check the YAML inventory:
```
$ ansible all -i inventory.yml -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Check that the servers' components are installed:
```
$ ansible app -m command -a 'ruby -v'
appserver | CHANGED | rc=0 >>
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]

$ ansible app -m command -a 'bundler -v'
appserver | CHANGED | rc=0 >>
Bundler version 1.11.2

$ ansible app -m command -a 'ruby -v; bundler -v'
appserver | FAILED | rc=1 >>
ruby: invalid option -;  (-h will show valid options) (RuntimeError)non-zero return code

$ ansible app -m shell -a 'ruby -v; bundler -v'
appserver | CHANGED | rc=0 >>
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
Bundler version 1.11.2

$ ansible db -m command -a 'systemctl status mongod'
dbserver | CHANGED | rc=0 >>
??? mongod.service - MongoDB Database Server
   Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-06-26 14:15:50 UTC; 30min ago
     Docs: https://docs.mongodb.org/manual
 Main PID: 795 (mongod)
   CGroup: /system.slice/mongod.service
           ??????795 /usr/bin/mongod --config /etc/mongod.conf

Jun 26 14:15:50 fhm4434fmipdb6jqmbtg systemd[1]: Started MongoDB Database Server.

$ ansible db -m systemd -a name=mongod
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "name": "mongod",
    "status": {
        ...
        "ActiveState": "active",
        ...
    }
}

$ ansible db -m service -a name=mongod
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "name": "mongod",
    "status": {
        ...
        "ActiveState": "active",
        ...
    }
}
```

Clone the application repository:
```
$ ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/ubuntu/reddit'
appserver | SUCCESS => {
    "after": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "before": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "changed": false,
    "remote_url_changed": false
}
```

Check the application cloning playbook:
```
$ ansible-playbook clone.yml

PLAY [Clone] *****************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [appserver]

TASK [Clone repo] ************************************************************************************************
ok: [appserver]

PLAY RECAP *******************************************************************************************************
appserver                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Generate an inventory file:
```
$ rm inventory

$ cd ../terraform/stage

$ terraform init -upgrade
Upgrading modules...
- app in ../modules/app
- db in ../modules/db
- vpc in ../modules/vpc

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/null...
- Finding yandex-cloud/yandex versions matching "~> 0.73.0"...
- Finding latest version of hashicorp/local...
- Installing hashicorp/local v2.2.3...
- Installed hashicorp/local v2.2.3 (signed by HashiCorp)
- Using previously-installed hashicorp/null v3.1.1
- Using previously-installed yandex-cloud/yandex v0.73.0
...

$ terraform apply -auto-approve
...

Plan: 1 to add, 0 to change, 0 to destroy.
local_file.generate_ansible_inventory: Creating...
local_file.generate_ansible_inventory: Provisioning with 'local-exec'...
local_file.generate_ansible_inventory (local-exec): Executing: ["/bin/sh" "-c" "chmod a-x ../../ansible/inventory"]
local_file.generate_ansible_inventory: Creation complete after 0s [id=7eb16f96cbe45c891272af43cb47f94731fe54b8]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.89.224"
external_ip_address_db = "51.250.95.242"

$ cd ../../ansible

$ cat inventory
[app]
appserver ansible_host=51.250.89.224

[db]
dbserver ansible_host=51.250.95.242
```

Check the dynamic inventory (uncomment the dynamic inventory file usage in `ansible.cfg`):
```
$ ./inventory.sh --list
{
  "app": {
    "hosts": [
      "51.250.89.224"
    ]
  },
  "db": {
    "hosts": [
      "51.250.95.242"
    ]
  }
}

$ ansible all -m ping
51.250.89.224 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
51.250.95.242 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Useful links:
- [???????????????????????? ?????????????????? ?? Ansible](https://nklya.medium.com/%D0%B4%D0%B8%D0%BD%D0%B0%D0%BC%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%BE%D0%B5-%D0%B8%D0%BD%D0%B2%D0%B5%D0%BD%D1%82%D0%BE%D1%80%D0%B8-%D0%B2-ansible-9ee880d540d6)

</details>


## Homework #11: ansible-2

- Disabled provisioning in Terraform infrastructure definition.
- Implemented MongoDB configuration.
- Implemented Puma HTTP server configuration.
- Implemented the application deployment.
- Splitted the playbook into several plays.
- Splitted the playbook into several playbooks.
- Configured [Yandex.Cloud inventory plugin](https://github.com/ansible/ansible/pull/61722).
- Used Ansible for Packer images provisioning.

<details><summary>Details</summary>

Recreate the `stage` infrastructure without provisioning:
```
$ cd ../terraform/stage

$ terraform destroy -auto-approve
...
Destroy complete! Resources: 7 destroyed.

$ terraform apply -auto-approve
...
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.95.160"
external_ip_address_db = "51.250.81.186"

$ cd ../../ansible

$ cat inventory
[app]
appserver ansible_host=51.250.95.160

[db]
dbserver ansible_host=51.250.81.186
```

Configure MongoDB:
```
$ ansible-playbook reddit_app_one_play.yml --check --limit db

PLAY [Configure hosts & deploy application] **********************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [dbserver]

TASK [Change mongo config file] **********************************************************************************
changed: [dbserver]

RUNNING HANDLER [restart mongod] *********************************************************************************
changed: [dbserver]

PLAY RECAP *******************************************************************************************************
dbserver                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

$ ansible-playbook reddit_app_one_play.yml --limit db

PLAY [Configure hosts & deploy application] **********************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [dbserver]

TASK [Change mongo config file] **********************************************************************************
changed: [dbserver]

RUNNING HANDLER [restart mongod] *********************************************************************************
changed: [dbserver]

PLAY RECAP *******************************************************************************************************
dbserver                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Configure Puma HTTP server.
```
$ cd ../terraform/stage

$ terraform apply -auto-approve
...
Terraform will perform the following actions:

  # local_file.generate_ansible_inventory must be replaced
...

Plan: 1 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  + internal_ip_address_db = "192.168.10.18"
...

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

external_ip_address_app = "51.250.95.160"
external_ip_address_db = "51.250.81.186"
internal_ip_address_db = "192.168.10.18"

$ cd ../../ansible/

$ cat inventory
[app]
appserver ansible_host=51.250.95.160 db_host=192.168.10.18

[db]
dbserver ansible_host=51.250.81.186

$ ./inventory.sh --list
{
  "app": {
    "hosts": [
      "51.250.95.160"
    ],
    "vars": {
      db_host: "192.168.10.18"
    }
  },
  "db": {
    "hosts": [
      "51.250.81.186"
    ]
  }
}

$ ansible-playbook reddit_app_one_play.yml --limit app --tags app-tag

PLAY [Configure hosts & deploy application] **********************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [appserver]

TASK [Add unit file for Puma] ************************************************************************************
changed: [appserver]

TASK [Add config for DB connection] ******************************************************************************
changed: [appserver]

TASK [Enable Puma] ***********************************************************************************************
changed: [appserver]

RUNNING HANDLER [reload puma] ************************************************************************************
changed: [appserver]

PLAY RECAP *******************************************************************************************************
appserver                  : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Deploy the application:
```
$ ansible-playbook reddit_app_one_play.yml --limit app --tags deploy-tag

PLAY [Configure hosts & deploy application] **********************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [appserver]

TASK [Install Git] ***********************************************************************************************
changed: [appserver]

TASK [Fetch the latest version of application code] **************************************************************
changed: [appserver]

TASK [Bundle install] ********************************************************************************************
ok: [appserver]

RUNNING HANDLER [reload puma] ************************************************************************************
changed: [appserver]

PLAY RECAP *******************************************************************************************************
appserver                  : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Open http://51.250.95.160:9292/ and check the application.

Check the playbook with separated plays:
```
$ cd ../terraform/stage

$ terraform destroy -auto-approve
...

$ terraform apply -auto-approve
...

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.79.219"
external_ip_address_db = "51.250.93.216"
internal_ip_address_db = "192.168.10.18

$ cd ../../ansible

$ ansible-playbook reddit_app_multiple_plays.yml

PLAY [Configure MongoDB] *****************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [dbserver]

TASK [Change mongo config file] **********************************************************************************
changed: [dbserver]

RUNNING HANDLER [restart mongod] *********************************************************************************
changed: [dbserver]

PLAY [Configure application] *************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [appserver]

TASK [Add unit file for Puma] ************************************************************************************
changed: [appserver]

TASK [Add config for DB connection] ******************************************************************************
changed: [appserver]

TASK [Enable Puma] ***********************************************************************************************
changed: [appserver]

RUNNING HANDLER [reload puma] ************************************************************************************
changed: [appserver]

PLAY [Deploy application] ****************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [appserver]

TASK [Install Git] ***********************************************************************************************
changed: [appserver]

TASK [Fetch the latest version of application code] **************************************************************
changed: [appserver]

TASK [Bundle install] ********************************************************************************************
changed: [appserver]

RUNNING HANDLER [reload puma] ************************************************************************************
changed: [appserver]

PLAY RECAP *******************************************************************************************************
appserver                  : ok=10   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
dbserver                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Open http://51.250.79.219:9292/ and check the application.

Check the splitted playbooks:
```
$ cd ../terraform/stage

$ terraform destroy -auto-approve
...

$ terraform apply -auto-approve
...

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.83.235"
external_ip_address_db = "51.250.79.18"
internal_ip_address_db = "192.168.10.13"

$ cd ../../ansible

$ ansible-playbook site.yml
...
PLAY RECAP *******************************************************************************************************
appserver                  : ok=10   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
dbserver                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Open http://51.250.83.235:9292/ and check the application.

Test [Yandex.Cloud inventory plugin](https://github.com/ansible/ansible/pull/61722) (I had to patch it in order to make it work):
```
$ pip install -r requirements.txt
...
Installing collected packages: pyjwt, protobuf, grpcio, googleapis-common-protos, yandexcloud
Successfully installed googleapis-common-protos-1.56.3 grpcio-1.47.0 protobuf-4.21.2 pyjwt-2.4.0 yandexcloud-0.10.1

$ ansible-inventory -i inventory_yc_compute.yml --playbook-dir ./ --vars --graph
@all:
  |--@app:
  |  |--51.250.83.235
  |  |  |--{ansible_host = 51.250.83.235}
  |  |  |--{internal_ip = 192.168.10.27}
  |--@db:
  |  |--51.250.79.18
  |  |  |--{ansible_host = 51.250.79.18}
  |  |  |--{internal_ip = 192.168.10.13}
  |--@ungrouped:

```

I don't use this inventory plugin for my playbooks because I parameterized the application host with the `db_host` variable (the internal IP of the DB host).  This plugin doesn't allow one host to be parameterized with some data from another host.
```
$ ansible-playbook -i inventory_yc_compute.yml site.yml --check

PLAY [Configure MongoDB] *****************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [51.250.79.18]

TASK [Change mongo config file] **********************************************************************************
changed: [51.250.79.18]

RUNNING HANDLER [restart mongod] *********************************************************************************
changed: [51.250.79.18]

PLAY [Configure application] *************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [51.250.83.235]

TASK [Add unit file for Puma] ************************************************************************************
changed: [51.250.83.235]

TASK [Add config for DB connection] ******************************************************************************
An exception occurred during task execution. To see the full traceback, use -vvv. The error was: ansible.errors.AnsibleUndefinedVariable: 'db_host' is undefined
fatal: [51.250.83.235]: FAILED! => {"changed": false, "msg": "AnsibleUndefinedVariable: 'db_host' is undefined"}

RUNNING HANDLER [reload puma] ************************************************************************************

PLAY RECAP *******************************************************************************************************
51.250.83.235              : ok=2    changed=1    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
51.250.79.18               : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Useful links:

- [Ansible Custom Inventory Plugin - a hands-on, quick start guide](https://termlen0.github.io/2019/11/16/observations/)

Create base images for the DB and the application using Ansible for images provisioning:
```
$ cd ../terraform/stage

$ terraform destroy -auto-approve
...
Destroy complete! Resources: 4 destroyed.

$ cd ../../

$ packer build -var-file=packer/variables.json packer/app.json
...
==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-app-base-1656502406 (id: fd85on9l66kfloap9i9l) with family name reddit-app-base

$ packer build -var-file=packer/variables.json packer/db.json
...
==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-db-base-1656503656 (id: fd8h8fuoqmepfmgfiqrr) with family name reddit-db-base

$ yc compute image list
+----------------------+----------------------------+-----------------+----------------------+--------+
|          ID          |            NAME            |     FAMILY      |     PRODUCT IDS      | STATUS |
+----------------------+----------------------------+-----------------+----------------------+--------+
| fd84km3m351crgj9upkq | reddit-app-base-1655934193 | reddit-app-base | f2ej52ijfor6n4fg5v0f | READY  |
| fd85on9l66kfloap9i9l | reddit-app-base-1656502406 | reddit-app-base | f2ej52ijfor6n4fg5v0f | READY  |
| fd87q6i0re98bj8v6fgc | reddit-base-1655732400     | reddit-base     | f2ej52ijfor6n4fg5v0f | READY  |
| fd89dv82hadttcirp1hr | reddit-base-1655736298     | reddit-base     | f2ej52ijfor6n4fg5v0f | READY  |
| fd8a5el5f41qgp5qjd8p | reddit-full-1655742289     | reddit-full     | f2ej52ijfor6n4fg5v0f | READY  |
| fd8bvuaat05ogds90rte | reddit-db-base-1655933993  | reddit-db-base  | f2ej52ijfor6n4fg5v0f | READY  |
| fd8h8fuoqmepfmgfiqrr | reddit-db-base-1656503656  | reddit-db-base  | f2ej52ijfor6n4fg5v0f | READY  |
+----------------------+----------------------------+-----------------+----------------------+--------+
```

Check the new images:
```
$ cd terraform/stage

$ terraform apply -auto-approve
...

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.94.92"
external_ip_address_db = "51.250.71.20"
internal_ip_address_db = "192.168.10.12"

$ cd ../../ansible

$ ansible-playbook site.yml
...
PLAY RECAP *******************************************************************************************************
appserver                  : ok=10   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
dbserver                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Open http://51.250.94.92:9292/ and check the application.

Destroy the infrastructure:
```
$ cd ../terraform/stage

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 5 destroyed.
```

- Useful links:

- [Use different signature algorithm for SSH host key #69](https://github.com/hashicorp/packer-plugin-ansible/issues/69)
- [ansible provisioner fails with "failed to transfer file" #11783](https://github.com/hashicorp/packer/issues/11783)
- [Packer/Ansible: Unable to acquire dpkg lock](https://joelvasallo.com/packer-ansible-unable-to-acquire-dpkg-lock-c7eb5863127d)
- [Ansible-lint warn 301 Commands should not change things if nothing needs doing #144](https://github.com/geerlingguy/ansible-role-certbot/issues/144)
- [Ansible-lint - Rule 306](https://xan.manning.io/2019/03/21/ansible-lint-rule-306.html#:~:text=%5B306%5D%20Shells%20that%20use%20pipes,considered%20a%20success%20by%20Ansible.)

</details>


## Homework #12: ansible-3

- Created roles for the DB and the application configuration.
- Configured the prod and the stage environments.
- Made the application available on port 80 using `jdauphant.nginx` role.
- Used Ansible Vault to store secrets.
- Configured Github CI to run linters.

<details><summary>Details</summary>

Check the deployment with roles:
```
$ cd ../terraform/stage

$ terraform apply -auto-approve
...

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.74.84"
external_ip_address_db = "51.250.81.2"
internal_ip_address_db = "192.168.10.8"

$ cd ../../ansible

$ ansible-playbook site.yml
...
PLAY RECAP *******************************************************************************************************
appserver                  : ok=10   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
dbserver                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Check the prod and stage environments deployment:
```
$ cd ../terraform/stage

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 4 destroyed.

$ terraform apply -auto-approve
...

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.88.81"
external_ip_address_db = "51.250.86.134"
internal_ip_address_db = "192.168.10.25"

$ cd ../../ansible

$ ansible-playbook -i environments/stage/inventory playbooks/site.yml

PLAY [Configure MongoDB] **********************************************************************************

TASK [Gathering Facts] ************************************************************************************
ok: [dbserver]

TASK [db : Show info about the env this host belongs to] ****************************************************
ok: [dbserver] => {
    "msg": "This host is in stage environment"
}

...

PLAY RECAP *************************************************************************************************
appserver                  : ok=11   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
dbserver                   : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

$ cd ../terraform/stage

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 5 destroyed.

$ cd ../prod

$ terraform apply -auto-approve
...

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.70.10"
external_ip_address_db = "51.250.86.36"
internal_ip_address_db = "192.168.10.25"

$ cd ../../ansible

$ ansible-playbook -i environments/prod/inventory playbooks/site.yml

PLAY [Configure MongoDB] **********************************************************************************

TASK [Gathering Facts] ************************************************************************************
ok: [dbserver]

TASK [db : Show info about the env this host belongs to] ****************************************************
ok: [dbserver] => {
    "msg": "This host is in prod environment"
}

...

PLAY RECAP *************************************************************************************************
appserver                  : ok=11   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
dbserver                   : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

$ cd ../terraform/prod

$ terraform destroy --auto-approve
...

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

Check the `jdauphant.nginx` role.
```
$ cd ../stage

$ terraform apply -auto-approve
...

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.70.10"
external_ip_address_db = "51.250.74.115"
internal_ip_address_db = "192.168.10.3"

$ cd ../../ansible

$ ansible-galaxy install -r environments/stage/requirements.yml
Starting galaxy role install process
- downloading role 'nginx', owned by jdauphant
- downloading role from https://github.com/jdauphant/ansible-role-nginx/archive/v2.21.1.tar.gz
- extracting jdauphant.nginx to /Users/vshender/.../vshender_infra/ansible/roles/jdauphant.nginx
- jdauphant.nginx (v2.21.1) was installed successfully

$ ansible-playbook -i environments/stage/inventory playbooks/site.yml
...

PLAY RECAP *******************************************************************************************************
appserver                  : ok=28   changed=19   unreachable=0    failed=0    skipped=17   rescued=0    ignored=0
dbserver                   : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Open http://51.250.70.10/ and check the application.

Destroy the infrastructure:
```
$ cd ../terraform/stage

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 5 destroyed.
```

Encrypt users info:
```
$ cd ../../ansible

$ ansible-vault encrypt environments/prod/credentials.yml
Encryption successful

$ ansible-vault encrypt environments/stage/credentials.yml
Encryption successful
```

Check that users are created on deployment:
```
$ cd ../terraform/stage

$ terraform apply -auto-approve
...

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.65.251"
external_ip_address_db = "51.250.1.5"
internal_ip_address_db = "192.168.10.22"

$ cd ../../ansible

$ pip install -r requirements.txt
...
Successfully installed passlib-1.7.4

$ ansible-playbook playbooks/site.yml
...

$ ssh -i ~/.ssh/appuser ubuntu@51.250.65.251
...
ubuntu@fhmvuv8v3jit0qahatlu:~$ cat /etc/passwd
...
ubuntu:x:1000:1001:Ubuntu:/home/ubuntu:/bin/bash
admin:x:1001:1002::/home/admin:
qauser:x:1002:1003::/home/qauser:

ubuntu@fhmvuv8v3jit0qahatlu:~$ cat /etc/group
...
ubuntu:x:1001:
admin:x:1002:
qauser:x:1003:

ubuntu@fhmvuv8v3jit0qahatlu:~$ exit
logout
Connection to 51.250.65.251 closed.

$ ssh -i ~/.ssh/appuser ubuntu@51.250.1.5
...
ubuntu@fhm0f43budki7i44u58o:~$ cat /etc/passwd
...
ubuntu:x:1000:1001:Ubuntu:/home/ubuntu:/bin/bash
mongodb:x:108:65534::/home/mongodb:/bin/false
admin:x:1001:1002::/home/admin:
qauser:x:1002:1003::/home/qauser:

ubuntu@fhm0f43budki7i44u58o:~$ cat /etc/group
...
ubuntu:x:1001:
mongodb:x:112:mongodb
admin:x:1002:
qauser:x:1003:

ubuntu@fhm0f43budki7i44u58o:~$ exit
logout
Connection to 51.250.1.5 closed.
```

Check that the dynamic inventory works:
```
$ environments/stage/inventory.sh --list
{
  "app": {
    "hosts": [
      "51.250.65.251"
    ],
    "vars": {
      "db_host": "192.168.10.22"
    }
  },
  "db": {
    "hosts": [
      "51.250.1.5"
    ]
  }
}

$ ansible-playbook -i environments/stage/inventory.sh playbooks/site.yml
...
PLAY RECAP *******************************************************************************************************
51.250.1.5                 : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
51.250.65.251              : ok=23   changed=0    unreachable=0    failed=0    skipped=17   rescued=0    ignored=0
```

Destroy the infrastructure:
```
$ cd ../terraform/stage

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 5 destroyed.
```

</details>


## Homework #13: ansible-4

- Created `Vagrantfile` for the local infrastructure.
- Added provisioning for the local infrastructure.
- Added tests for the `db` role.
- Used the `db` and `app` roles for packer provisioning.

<details><summary>Details</summary>

Check Vagrant:
```
$ cd ansible

$ vagrant up
...

$ vagrant box list
ubuntu/focal64  (virtualbox, 20210304.0.0)
ubuntu/xenial64 (virtualbox, 20210316.0.0)

$ vagrant status
Current machine states:

dbserver                  running (virtualbox)
appserver                 running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.

$ vagrant ssh appserver
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-204-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

0 packages can be updated.
0 of these updates are security updates.

vagrant@appserver:~$ ping -c 2 192.168.56.20
PING 192.168.56.20 (192.168.56.20) 56(84) bytes of data.
64 bytes from 192.168.56.20: icmp_seq=1 ttl=64 time=0.095 ms
64 bytes from 192.168.56.20: icmp_seq=2 ttl=64 time=0.043 ms

--- 192.168.56.20 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 999ms
rtt min/avg/max/mdev = 0.043/0.069/0.095/0.026 ms

vagrant@appserver:~$ exit
logout
```

Check the local infrastructure provisioning:
```
$ vagrant provision
...

PLAY RECAP *********************************************************************
dbserver                   : ok=9    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

...

PLAY RECAP *********************************************************************
appserver                  : ok=30   changed=18   unreachable=0    failed=0    skipped=18   rescued=0    ignored=0
```

Open http://192.168.56.20/ and check the application.

Destroy the local infrastructure:
```
$ vagrant destroy -f
==> appserver: Forcing shutdown of VM...
==> appserver: Destroying VM and associated drives...
==> dbserver: Forcing shutdown of VM...
==> dbserver: Destroying VM and associated drives...
```

A Molecule scenario creation for the `db` role:
```
$ pip install -r requirements.txt
...
Successfully installed arrow-1.2.2 binaryornot-0.4.4 cerberus-1.3.2 chardet-5.0.0 click-8.1.3 click-help-colors-0.9.1 cookiecutter-2.1.1 distro-1.7.0 jinja2-time-0.2.0 molecule-4.0.0 molecule-vagrant-1.0.0 pytest-testinfra-6.8.0 python-dateutil-2.8.2 python-slugify-6.1.2 python-vagrant-1.0.0 selinux-0.2.1 testinfra-6.0.0 text-unidecode-1.3

$ molecule --version
molecule 4.0.0 using python 3.10
    ansible:2.13.1
    delegated:4.0.0 from molecule

$ ansible --version
ansible [core 2.13.1]
  config file = .../vshender_infra/ansible/ansible.cfg
  configured module search path = ['/Users/vshender/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /Users/vshender/.virtualenvs/vshender_infra/lib/python3.10/site-packages/ansible
  ansible collection location = /Users/vshender/.ansible/collections:/usr/share/ansible/collections
  executable location = /Users/vshender/.virtualenvs/vshender_infra/bin/ansible
  python version = 3.10.4 (main, May 19 2022, 21:19:38) [Clang 12.0.5 (clang-1205.0.22.9)]
  jinja version = 3.1.2
  libyaml = True

$ cd roles/db

$ molecule init scenario --role-name db --driver-name vagrant
INFO     Initializing new scenario default...
INFO     Initialized scenario in .../vshender_infra/ansible/roles/db/molecule/default successfully.
```

Playing with Molecule:
```
$ molecule create
INFO     default scenario test matrix: dependency, create, prepare
...
INFO     Running default > create

PLAY [Create] ******************************************************************

...

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

INFO     Running default > prepare

PLAY [Prepare] *****************************************************************

...

PLAY RECAP *********************************************************************
instance                   : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

$ molecule list
INFO     Running default > list
                ???             ???                  ???               ???         ???
  Instance Name ??? Driver Name ??? Provisioner Name ??? Scenario Name ??? Created ??? Converged
????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  instance      ??? vagrant     ??? ansible          ??? default       ??? true    ??? false
                ???             ???                  ???               ???         ???

$ molecule login -h instance
INFO     Running default > login
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-204-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

0 packages can be updated.
0 of these updates are security updates.

New release '18.04.6 LTS' available.
Run 'do-release-upgrade' to upgrade to it.


Last login: Sun Jul  3 13:35:42 2022 from 10.0.2.2
vagrant@instance:~$ exit
logout

$ molecule converge
INFO     default scenario test matrix: dependency, create, prepare, converge
...
INFO     Running default > converge

PLAY [Converge] ****************************************************************

...

PLAY RECAP *********************************************************************
instance                   : ok=9    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

$ molecule list
INFO     Running default > list
                ???             ???                  ???               ???         ???
  Instance Name ??? Driver Name ??? Provisioner Name ??? Scenario Name ??? Created ??? Converged
????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  instance      ??? vagrant     ??? ansible          ??? default       ??? true    ??? true
                ???             ???                  ???               ???         ???

$ molecule verify
molecule verify
INFO     default scenario test matrix: verify
...
INFO     Running default > verify
INFO     Executing Testinfra tests found in .../vshender_infra/ansible/roles/db/molecule/default/tests/...
============================= test session starts ==============================
platform darwin -- Python 3.10.4, pytest-7.1.2, pluggy-1.0.0
rootdir: /Users/vshender
plugins: testinfra-6.0.0, testinfra-6.8.0
collected 3 items

molecule/default/tests/test_default.py ...                               [100%]

============================== 3 passed in 4.53s ===============================
INFO     Verifier completed successfully.

$ molecule destroy
INFO     default scenario test matrix: dependency, cleanup, destroy
...

PLAY [Destroy] *****************************************************************

...

PLAY RECAP *********************************************************************
localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

INFO     Pruning extra files from scenario ephemeral directory

$ molecule list
INFO     Running default > list
                ???             ???                  ???               ???         ???
  Instance Name ??? Driver Name ??? Provisioner Name ??? Scenario Name ??? Created ??? Converged
????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  instance      ??? vagrant     ??? ansible          ??? default       ??? false   ??? false
                ???             ???                  ???               ???         ???
```

Run the `db` role tests:
```
$ molecule test
INFO     default scenario test matrix: dependency, lint, cleanup, destroy, syntax, create, prepare, converge, idempotence, side_effect, verify, cleanup, destroy
...
INFO     Running default > destroy

PLAY [Destroy] *****************************************************************

...

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

INFO     Running default > syntax

playbook: .../vshender_infra/ansible/roles/db/molecule/default/converge.yml
INFO     Running default > create

PLAY [Create] *****************************************************************

...

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

INFO     Running default > prepare

PLAY [Prepare] *****************************************************************

...

PLAY RECAP *********************************************************************
instance                   : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

INFO     Running default > converge

PLAY [Converge] ****************************************************************

...

PLAY RECAP *********************************************************************
instance                   : ok=9    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

INFO     Running default > idempotence

PLAY [Converge] ****************************************************************

...

PLAY RECAP *********************************************************************
instance                   : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

INFO     Idempotence completed successfully.
INFO     Running default > side_effect
WARNING  Skipping, side effect playbook not configured.
INFO     Running default > verify
INFO     Executing Testinfra tests found in .../vshender_infra/ansible/roles/db/molecule/default/tests/...
============================= test session starts ==============================
platform darwin -- Python 3.10.4, pytest-7.1.2, pluggy-1.0.0
rootdir: /Users/vshender
plugins: testinfra-6.0.0, testinfra-6.8.0
collected 3 items

molecule/default/tests/test_default.py ...                               [100%]

============================== 3 passed in 4.27s ===============================
INFO     Verifier completed successfully.
INFO     Running default > cleanup
WARNING  Skipping, cleanup playbook not configured.
INFO     Running default > destroy

PLAY [Destroy] *****************************************************************

...

PLAY RECAP *********************************************************************
localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

INFO     Pruning extra files from scenario ephemeral directory
```

</details>
