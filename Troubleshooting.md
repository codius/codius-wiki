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

## Code: F00, name: NotAcceptedError, data: Incorrect token for account

```
2018-06-19T18:46:50.893Z ilp-plugin-btp debug processing btp packet {"type":2,"requestId":2269582638,"data":{"code":"F00","name":"NotAcceptedError","triggeredAt":"2018-06-19T18:46:52.103Z","data":"incorrect token for account. account=c8 token=6d55aa9bde89d15eb2f79f83c2911a8573114d21e4692e33ca2fb326b61ff5e2","protocolData":[]}}
2018-06-19T18:46:50.894Z ilp-plugin-btp debug received BTP packet (TYPE_ERROR, RequestId: 2269582638): {"code":"F00","name":"NotAcceptedError","triggeredAt":"2018-06-19T18:46:52.103Z","data":"incorrect token for account. account=c8 token=6d55aa9bde89d15eb2f79f83c2911a8573114d21e4692e33ca2fb326b61ff5e2","protocolData":[]}
(node:17462) UnhandledPromiseRejectionWarning: Error: {"code":"F00","name":"NotAcceptedError","triggeredAt":"2018-06-19T18:46:52.103Z","data":"incorrect token for account. account=c8 token=6d55aa9bde89d15eb2f79f83c2911a8573114d21e4692e33ca2fb326b61ff5e2","protocolData":[]}
```

#### Problem

The automatically generated token that your account uses does not match the token
that the connector associates with your account. This could mean that the `name`
you're using is already taken, or it might just mean you broke your configuration
by accident when changing it.

#### Solution

You can solve this by making sure you have a freshly created channel with a unique
`name`. Follow [Creating a New Channel with Moneyd](#creating-a-new-channel-with-moneyd).

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
oftentimes you need to do a harder reset. Follow
[Creating a New Channel with Moneyd](#creating-a-new-channel-with-moneyd).

This should be sufficient to fix this problem, and most other moneyd issues. It
works by wiping your channels and recreating them. This operation is free,
aside from the negligible network fees.

## Error: connect ECONNREFUSED 127.0.0.1:7768

```
2018-06-11T00:19:47.174Z ilp-ws-reconnect debug websocket disconnected with Error: connect ECONNREFUSED 127.0.0.1:7768; reconnect in 5000
```

#### Problem

7768 is the port that moneyd is ran on. When you get this error, it means that codiusd is unable to connect to moneyd.

Moneyd could be failing for a number of reasons, but some common ones are not enough XRP in your wallet or your ILP connector is having some issues.

#### Solution 

Check if moneyd is running by entering `systemctl status moneyd-xrp`.

If it is running, you can stop is start again in debug mode with these commands:

```
systemctl stop moneyd-xrp
DEBUG=* moneyd xrp:start
```

You can get more in depth errors via debug mode that may be able to help fix your issue.

## Creating a New Channel with Moneyd

#### Part 1: Clean up channels

- Run `moneyd xrp:cleanup`.
- Mark all of your channels for deletion by hitting `a`.
  - If you don't have any channels, skip to [Part 2: Create New Channels](#part-2-create-new-channels)
- Confirm their deletion by hitting `<enter>`.
- Run `moneyd xrp:info`. You'll see that your channels expire in an hour.
- Wait one hour.
- Run `moneyd xrp:info`. You'll see that your channels are `ready to close`.
- Run `moneyd xrp:cleanup`.
- Mark all channels for deletion with `a`.
- Confirm deletion by hitting `<enter>`.

#### Part 2: Create New channels

- On every machine using moneyd with that XRP account, back up your `.moneyd.json`.
- On every machine using moneyd with that XRP account, run `moneyd xrp:configure --advanced`
- Put your secret back in.
- When you're prompted for `name`, give a unique value using alphanumeric characters.
- Now start moneyd.
