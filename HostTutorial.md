# Setting Up a Codius Host

In the smart program ecosystem that Codius creates, a relationship is established between hosts and developers that allows for a wealth of hosting options for the developer and allows the host to receive payment for hosting said code. For the aspiring Codius host, this post will explain the steps necessary to launch one for themselves.

## Prerequisites

You need to have a server to run Codius on, which should meet the following specs:

- CentOS 7. This tutorial assumes you’re using CentOS 7 and that’s the only OS that is officially supported right now. We’re working on providing instructions for other Linux distributions.
- x86-64 architecture. You need a modern 64-bit processor. Unfortunately, ARM is not yet supported.
- Virtualization support. Your Codius host is going to run contracts as VMs, so you need a processor that supports virtualization. Fortunately, most modern processors do.
- Bare metal (recommended). You can get bare metal instances from services like Packet and AWS. A VM will work, too, if it supports nested virtualization. But it will be less efficient.
- Root access. You’ll be installing software.
- At least 2 GB of memory, ideally more. Each contract will use 512 MB of memory. In addition, you will need some memory for the host OS itself.

In addition to the server, you need:

- An XRP Wallet. Support for other payment systems is in the works but right now, XRP is your best bet. Codius runs a local instance of Moneyd in order to handle payments. Note that your wallet needs to be funded, i.e. contain at least 36 XRP. Specifically, the wallet needs 16 XRP in addition to it’s current reserve. Also, the wallet you use here cannot be used with any other instance of Moneyd.
- A domain: You need to have your own domain which will act as the public hostname of your Codius host. E.g. `codius.example.com`
If you want to run multiple Codius hosts under the same domain, you can just number them, like `codius1.example.com`, `codius2.example.com`, etc.

# Basic Configuration

For this tutorial, we’re assuming you are root. If you are logged in as another user, run sudo su to switch to the root user.

Before we start, we need to make sure our system hostname is correctly configured. Run the following command and replace `codius.example.com` with your Codius hostname.

    hostnamectl set-hostname codius.example.com

Now we need to make sure the hostname is set correctly by running `uname -n`. This should print the hostname you just set:

    $ uname -n
    codius.example.com

Please make sure this command returns the correct hostname as we will be using it in some of the scripts later in this tutorial.

# Installation

[Codius](https://codius.org/) is an open-source decentralized hosting plaform, built with [Interledger](https://interledger.org/). With it, users can run software on servers anywhere in the world and pay for it using any currency. This tutorial will teach you how to create your own Codius host and start earning for hosting other developers' code in XRP.

A Codius host is comprised of three parts: [hyperd](https://github.com/hyperhq/hyperd), [moneyd](https://github.com/interledgerjs/moneyd), and [codiusd](https://github.com/coilhq/codiusd). Hyperd handles virtualization, Moneyd allows for Interledger payments, and Codiusd exposes endpoints for uploaders to send their code to the host.

A Codius Host is comprised of three main components:

- Hyperd — Handles virtualization and hardware isolation of code
- Moneyd — Allows the sending and receiving of payments on Interledger
- Codiusd — Exposes endpoints that allow developers to upload code to the host and launch pods for them.

## Installing Hyperd

[Hyperd](https://github.com/hyperhq/hyperd) allows the host to run uploaded code in a hardware-isolated [pod](https://kubernetes.io/docs/concepts/workloads/pods/pod/), which then allocates [containers](https://www.docker.com/what-container) for uploaded code when it is called.

SSH into your CentOS server and install the following packages:

    yum install -y gcc-c++ make
    curl -sSl https://codius.s3.amazonaws.com/hyper-bootstrap.sh | bash

This will install all of our RPM dependencies for NodeJS and hyperd, as well as automatically forward ports from the hyperd pods. It will also launch hyperd and allow you to use the hypercli command line interface.

## Installing Moneyd

[Moneyd](https://github.com/interledgerjs/moneyd) is a daemon that allows a host to send & receive payments over [Interledger](https://interledger.org/). In this setup it will be installed and configured to make payments with XRP but plugins for [Ethereum](https://github.com/interledgerjs/ilp-plugin-ethereum-asym-client) and other blockchains are being worked on. Keep an eye on the [current list of uplinks](https://github.com/interledgerjs/moneyd#uplinks).

    curl --silent --location https://rpm.nodesource.com/setup_10.x | bash -
    yum install -y nodejs
    yum install -y https://codius.s3.amazonaws.com/moneyd-xrp-4.0.1-1.x86_64.rpm

At this point, you will need your XRP Secret ready.

    moneyd xrp:configure 
    # You will be prompted to enter your secret here
    systemctl start moneyd-xrp

You can confirm the status of the daemon with `systemctl status moneyd-xrp`

## Installing Codiusd

[Codiusd](https://github.com/coilhq/codiusd) is the server-side component of Codius, which exposes endpoints that allow users to upload code and provision containers for them. It also proxies requests to pods that it is currently hosting.

    yum install -y git
    npm install -g codiusd --unsafe-perm

Finally, create a file called `codiusd.service` with the following contents in `/etc/systemd/system`:

    [Unit]
    Description=Codiusd
    After=network.target nss-lookup.target
    [Service]
    ExecStart=/usr/bin/npm start
    Environment="DEBUG=*"
    Environment="CODIUS_PUBLIC_URI=https://codius.example.com"
    WorkingDirectory=/usr/lib/node_modules/codiusd
    Restart=always
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=codiusd
    User=root
    Group=root
    [Install]
    WantedBy=multi-user.target

Then we need to edit this file to use our actual hostname.

    sed -i s/codius.example.com/`uname -n`/g /etc/systemd/system/codiusd.service

Alternatively you can pull the example file and save in one command:

    curl -sSl https://codius.s3.amazonaws.com/codiusd.service | sed s/codius.example.com/`uname -n`/ > /etc/systemd/system/codiusd.service

To start `codiusd`, you can run the following commands:

    systemctl enable codiusd
    systemctl start codiusd

Your codiusd server will now be running on port 3000. Manifests can be uploaded via endpoints at this address.

You can check on the status of the server with the command `systemctl status codiusd`

# Domain Setup

To set up your domain for use with Codius, you will perform the following steps:

- Add DNS records that point to your Codius host
- Request a wildcard TLS certificate from Let's Encrypt
- Setup an nginx reverse proxy

## Adding DNS Records

In order to run Codius, we need a primary hostname for our Codius host and we need any subdomains to point to our host also. For example, if your domain is `example.com`, you need to point `codius.example.com` to your Codius host, including any subdomains like `xyz.codius.example.com`.

To achieve that, we create two A records:

    codius.example.com.    300     IN      A       203.0.113.1
    *.codius.example.com.  300     IN      A       203.0.113.1

Replace `codius.example.com` with your Codius hostname and `203.0.113.1` with the IP address of your Codius host.

Make sure you can ping your Codius host under its new hostname:

    $ ping -c 1 codius.example.com
    PING codius.example.com (203.0.113.1) 56(84) bytes of data.
    64 bytes from 203.0.113.1 (203.0.113.1): icmp_seq=1 ttl=48 time=4.13 ms
    --- codius.example.com ping statistics ---
    1 packets transmitted, 1 received, 0% packet loss, time 0ms
    rtt min/avg/max/mdev = 4.131/4.131/4.131/0.000 ms

And make sure it can be reached for any arbitrary subdomain as well:

    $ ping -c 1 foobar.codius.example.com
    PING foobar.codius.example.com (203.0.113.1) 56(84) bytes of data.
    64 bytes from 203.0.113.1 (203.0.113.1): icmp_seq=1 ttl=48 time=3.72 m
    --- foobar.codius.example.com ping statistics ---
    1 packets transmitted, 1 received, 0% packet loss, time 0ms
    rtt min/avg/max/mdev = 3.722/3.722/3.722/0.000 ms

Note that in both cases, the hostname resolved to our Codius host's IP address, `203.0.113.1`.

Now that our host is reachable, we're ready to request a TLS certificate.

## Requesting a Wildcard Certificate

Certificates used to be expensive. Thankfully, these days you can get free certs from Let's Encrypt. Please consider donating for this awesome service:

- Donating to ISRG / Let's Encrypt: [https://letsencrypt.org/donate](https://letsencrypt.org/donate)
- Donating to EFF: [https://eff.org/donate-le](https://eff.org/donate-le)

I'm going to donate 25$ right now. Meet you back here in a bit.

Ok, back? Let's get started.

First, we need to download certbot and install some dependencies:

    yum install -y git
    git clone https://github.com/certbot/certbot
    cd certbot
    git checkout v0.23.0
    ./certbot-auto -n --os-packages-only
    ./tools/venv.sh
    ln -s `pwd`/venv/bin/certbot /usr/local/bin/certbot

Now we are ready to request our certificate. Just run this command and follow the prompts.

    certbot -d `uname -n` -d *.`uname -n` --manual --preferred-challenges dns-01 --server https://acme-v02.api.letsencrypt.org/directory certonly

Certbot will:

- Ask you for your email address
- Ask you to agree to the Terms of Service for Let's Encrypt
- Ask you if you want to get ~~spam~~ important messages from EFF
- Ask you if you're ok with your IP being logged publicly
- Ask you to add a TXT record for `_acme-challenge.codius.example.com`
- Ask you to add a **second** TXT record for `_acme-challenge.codius.example.com`

  If using AWS, simply add the two records as separate lines as described [here](https://superuser.com/questions/573305/unable-to-create-txt-record-using-amazon-route-53).

Important: You need to add **both records as separate TXT records**. When you query `TXT _acme-challenge.codius.example.com`, you should see something like this:

    $ drill TXT _acme-challenge.codius.example.com
    ;; ->>HEADER<<- opcode: QUERY, rcode: NOERROR, id: 64965
    ;; flags: qr rd ra ; QUERY: 1, ANSWER: 2, AUTHORITY: 2, ADDITIONAL: 4
    ;; QUESTION SECTION:
    ;; _acme-challenge.codius.example.com. IN      TXT
    ;; ANSWER SECTION:
    _acme-challenge.codius.example.com.    300     IN      TXT     "QwHjEBqK2RBhk5XyjriHPmjf2h2Ijettgy4BpwdVNlY"
    _acme-challenge.codius.example.com.    300     IN      TXT     "YOMfcUWwPsW5hs2vl5AE/CRPg5m5BH7ORjEaUJReK4U"

If you did everything correctly, you should get a message like:

    IMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /etc/letsencrypt/live/codius.example.com/fullchain.pem
       Your key file has been saved at:
       /etc/letsencrypt/live/codius.example.com/privkey.pem
       Your cert will expire on 2018-09-04. To obtain a new or tweaked
       version of this certificate in the future, simply run certbot
       again. To non-interactively renew *all* of your certificates, run
       "certbot renew"
     - If you like Certbot, please consider supporting our work by:
       Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
       Donating to EFF:                    https://eff.org/donate-le

If you got this far, give yourself a pat on the back. The tough part is over!

Note that your certificate is only valid for 90 days. We'll cover how to set up automatic renewal in a future tutorial.

## Setting Up Nginx

Now we need to set up Nginx which will act as a reverse proxy for our Codius host. Nginx will receive any incoming traffic and forward it to Codiusd.

The first step for installing Nginx on CentOS 7 is to enable the EPEL repository:

    yum install -y epel-release

Then we can install Nginx itself.

    yum install -y nginx
    systemctl enable nginx
    echo 'return 301 https://$host$request_uri;' > /etc/nginx/default.d/ssl-redirect.conf
    openssl dhparam -out /etc/nginx/dhparam.pem 2048

To configure Nginx as a reverse proxy for Codius, create a file named `/etc/nginx/conf.d/codius.conf` with the following contents:

    map $http_upgrade $connection_upgrade {
      default upgrade;
      '' $http_connection;
    }
    server {
      listen 443 ssl;
      ssl_certificate /etc/letsencrypt/live/codius.example.com/fullchain.pem;
      ssl_certificate_key /etc/letsencrypt/live/codius.example.com/privkey.pem;
      ssl_protocols TLSv1.2;
      ssl_prefer_server_ciphers on;
      ssl_dhparam /etc/nginx/dhparam.pem;
      ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
      ssl_ecdh_curve secp384r1;
      ssl_session_timeout 10m;
      ssl_session_cache shared:SSL:10m;
      ssl_session_tickets off;
      ssl_stapling on;
      ssl_stapling_verify on;
      resolver 1.1.1.1 1.0.0.1 valid=300s;
      resolver_timeout 5s;
      add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
      add_header X-Frame-Options DENY;
      add_header X-Content-Type-Options nosniff;
      add_header X-XSS-Protection "1; mode=block";
      location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_buffering off;
      }
    }

Once again, we need to replace `example.codius.com` with the actual hostname:

    sed -i s/codius.example.com/`uname -n`/g /etc/nginx/conf.d/codius.conf

We need to make sure that SElinux is set to allow Nginx to act as a proxy:

    setsebool -P httpd_can_network_connect 1

Don't worry if it tells you that SElinux is disabled. In that case, the command above isn't needed but it also doesn't hurt anything.

Finally, we need to start Nginx:

    systemctl start nginx

## Open Port 443 in Firewalld

Your system may or may not come with firewalld preinstalled. If you find that you can't access [https://codius.example.com](https://codius.example.com/) for your host, try this command to open port 443:

    firewall-cmd --zone=public --add-port=443/tcp --permanent

## You're Done!

Now you should be able visit `https://codius.example.com/version` (replace `codius.example.com` with your hostname) and see output similar to this:

    {"name":"Codiusd (JavaScript)","version":"1.0.0"}

That's it! Your Codius host is up and running. It will automatically try to connect to the Codius network and tell other hosts about its existence.