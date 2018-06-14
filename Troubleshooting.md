# Troubleshooting

This is a partial list of some common errors that you might see when running
a codius host or uploading to codius.

Each of these errors is accompanied by an example stack trace so you can
identify it in your own logs.

If you encounter an error and do not have a solution to it yet, feel free to
make a pull request adding it to this list, and a codius contributor will add
the solution.

## Route Control Message Was Rejected

```
2018-06-14T16:52:55.153Z connector:ccp-receiver[parent] debug route control message was rejected. rejection={"code":"F00","triggeredBy":"g.scylla","message":"cannot process route control messages from non-peers.","data":{"type":"Buffer","data":[]}}
2018-06-14T16:52:55.154Z connector:ccp-receiver[parent] debug failed to set route control information on peer. error=Error: route control message rejected.
at plugin.sendData.then.data (/usr/lib/moneyd-xrp/moneyd/node_modules/ilp-connector/src/routing/ccp-receiver.ts:174:17)
at process._tickCallback (internal/process/next_tick.js:68:7)
2018-06-14T16:52:30.668Z connector:error-handler-middleware[local] debug error in data handler, creating rejection. ilpErrorCode=F00 error=BadRequestError: cannot process route control messages from non-peers.
```

#### Problem

In the Interledger network, connectors send routing information to one another.
In some peering relationships, a connector will choose to ignore these route
messages.

**This error message does not reflect any malfunction of moneyd, it's just a
warning of misconfiguration. It isn't responsible for any problems in routing
or any problems when sending payments.**

#### Solution

In version 1.1.1 on moneyd-uplink-xrp, this error should no long occur.  You
can run `npm upgrade -g moneyd-uplink-xrp` to install this patch.

## Code: F02, message: failed to send packet: no clients connected

```
ilp-protocol-stream:Client:Connection sending packet 2 with source amount: 0: {"sequence":"2","ilpPacketType":12,"prepareAmount":"0","frames":[{"type":1,"name":"ConnectionClose","errorCode":2,"errorMessage":"Unexpected error while sending packet. Code: F02, message: failed to send packet: No clients connected for account yXF-OL4i169Ci-RqTPQsxFuzSknGoNz3m35t5Wb0v3s"}]}) +165ms codius-cli:uploadHandler Pod Upload failed Error: Error connecting: Unexpected error while sending packet. Code: F02, message: failed to send packet: No clients connected for account yXF-OL4i169Ci-RqTPQsxFuzSknGoNz3m35t5Wb0v3s +569ms codius-cli:uploadHandler TypeError: Cannot read property 'status' of undefined codius-cli:uploadHandler at uploadToHosts (/usr/lib/node_modules/codius/src/handlers/upload.js:113:22) codius-cli:uploadHandler at process._tickCallback (internal/process/next_tick.js:68:7) +1ms
```

#### Problem

The host that you're sending money to has an ILP address, but their connection
to ILP has gone down.

This could be because the moneyd process ended or crashed. It could also be
because the moneyd instance lost its connection to its parent.

You may lose your connection to your parent because the parent went down. It
may also be due to a misconfiguration in moneyd that causes your parent to
block your sub-account.

If you ran `moneyd xrp:cleanup` and then tried to run moneyd without forcing a
new channel to be created, you'll encounter this error.

#### Solution

First, try restarting moneyd. This will fix the error in some situations, but
oftentimes you need to do a harder reset:

- Run `moneyd xrp:cleanup`.
- Mark all of your channels for deletion by hitting `a`.
- Confirm their deletion by hitting `<enter>`.
- Run `moneyd xrp:info`. You'll see that your channels expire in an hour.
- Wait one hour.
- Run `moneyd xrp:info`. You'll see that your channels are `ready to close`.
- Run `moneyd xrp:cleanup`.
- Mark all channels for deletion with `a`.
- Confirm deletion by hitting `<enter>`.
- On every machine using moneyd with that XRP account, back up your `.moneyd.json`.
- On every machine using moneyd with that XRP account, run `moneyd xrp:configure --advanced`
- Put your secret back in.
- When you're prompted for `name`, give a unique value using alphanumeric characters.
- Now start moneyd.

This should be sufficient to fix this problem, and most other moneyd issues. It
works by wiping your channels and recreating them. This operation is free,
aside from the negligible network fees.
