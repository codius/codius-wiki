# Frequently Asked Questions

The process of installing a Codius host or uploading a contract may come with its own issues or nuances. The most commonly occurring ones can be reported here.

## Contributing to the FAQ

If you wish to contribute something to the FAQ, add your contribution to `FAQ.md` in a separate branch in https://github.com/codius/codius-wiki. Open a pull request there for someone to review and update the wiki with your changes once they're ready.

New additions should follow this format:

### Describe the issue in a header
```
Add brief log output if it is relevant.
```
* Detail each step...
* In its own bullet point.
* Try to include pertinent but brief log messages in the header to help others find the issue.

### How much XRP do I need in my wallet used for a Codius host?
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

### How do I list pods (contracts) running on my host?
* Enter the command `hyperctl list`
```
[root@host1 ~]# hyperctl list
POD ID              POD Name            VM name             Status

< I have no pods running but details would appear here. Will update this FAQ once I have a better example >
[root@host1 ~]#
```

### Can I run multiple instances of Codius from one wallet?
Yes! 
* Add a unique name to your `.moneyd.json` in the `uplinks.xrp.options.name` for each instance.

More info and actual documentation found below: 
* https://github.com/interledgerjs/moneyd#multiple-instances
