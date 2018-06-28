# Frequently Asked Questions

The process of installing a Codius host or uploading a contract may come with its own issues or nuances. The most commonly occurring ones can be reported here.

- [Contributing to the FAQ](#contributing-to-the-faq)
- [Moneyd FAQs](#moneyd-faqs)
  - [How much XRP do I need in my wallet for a Codius host?](#how-much-xrp-do-i-need-in-my-wallet-for-a-codius-host)
  - [Can I run multiple instances of Codius from one wallet?](#can-i-run-multiple-instances-of-codius-from-one-wallet)
- [Codiusd FAQs](#codiusd-faqs)
  - [Should I run the setup as root user?](#should-i-run-the-setup-as-root-user)
  - [How do I list pods (contracts) running on my host?](#how-do-i-list-pods-contracts-running-on-my-host)
- [Codius CLI (Codius) FAQs](#codius-cli-codius-faqs)
  - [What decides if a contract (pod) is uploaded to my host? Is it random?](#what-decides-if-a-contract-pod-is-uploaded-to-my-host-is-it-random)

## Contributing to the FAQ

If you wish to contribute something to the FAQ, add your contribution to `FAQ.md` in a separate branch in https://github.com/codius/codius-wiki. Open a pull request there for someone to review and update the wiki with your changes once they're ready.

New additions should follow this format:

### Describe the issue in a header
```
Add brief log output if it is relevant.
```
* Detail each step...
* In its own bullet point.
* Be sure to add your contribution to the table of contents above to help others find the issue!
  * Format for the Table of Contents follows this format: `- [Describe the issue in a header](#describe-the-issue-in-a-header)`

## Moneyd FAQs

### How much XRP do I need in my wallet for a Codius host?
36+ XRP is required:
* 20 as base reserve (required for wallet activation)
* 10 escrowed in paymentChannelCreate tx
* 5 added to reserve to allow paymentChannel walelt functionality (now 25 in reserves)
* 1 XRP to facilitate the tx fees burned during these initial transactions.

If less than required XRP is in wallet, you will likely see this error on your host:
```
ilp-plugin-xrp-asym-client Error creating the payment channel: tecUNFUNDED One of _ADD, _OFFER, or _SEND. Deprecated. +0ms
```
* To rectify, add funds to your wallet and restart moneyd.

### Can I run multiple instances of Codius from one wallet?
Yes!
Check which version of [moneyd-uplink-xrp](https://github.com/interledgerjs/moneyd-uplink-xrp) you are using with the following command:
```
npm list -g | grep moneyd-uplink-xrp
```
#### If using v1.1.2 and later versions
* When you configure moneyd, you will be automatically assigned a random 32-byte name to your paymentChannel.
* You do not need to follow the steps below.

#### If using v1.1.1 and earlier versions
* Add a unique name to your moneyd configuration using the below function:
```
moneyd xrp:configure --advanced
```
* If running on a machine already setup with moneyd, you'll have to delete your `.moneyd.json` file first.
* If running on a machine already setup with moneyd, you'll need to run a `moneyd xrp:cleanup` to remove old paymentChannels.
* Tutorial coming soon

  More info and actual documentation found below: 
* https://github.com/interledgerjs/moneyd#multiple-instances
* https://github.com/interledgerjs/moneyd#clean-up-channels
## Codiusd FAQs

### Should I run the setup as root user?
Yes!
* Log in as root for entire setup process (hyper/moneyd/codiusd).
* Failure to do so will cause errors like the following (even using sudo):
```
could not create leading directories of '/root/.npm/_cacache/tmp/git-clone-57fb2ba2 permission denied`
```

### How do I list pods (contracts) running on my host?
* Enter the command `hyperctl list`
```
[root@host1 ~]# hyperctl list
POD ID                                                 POD Name                                               VM name             Status
lg6gjhhh2b3if2tzpbms6cr3hdmh7dixa2v4an6pz4tdxdmqtjpa   lg6gjhhh2b3if2tzpbms6cr3hdmh7dixa2v4an6pz4tdxdmqtjpa   vm-IgCwzBdZfd       running
```

## Codius CLI (Codius) FAQs

### What decides if a contract (pod) is uploaded to my host? Is it random?
* If `--host` is specified during upload, a specific host can be chosen;
* If `--host` is left out / blank, a random host is chosen from the list of peers.
```
codius upload /tmp/example-manifest.json --host https://host1.codius.live --duration 200
```
