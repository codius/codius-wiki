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

### How do I list pods (contracts) running on my host?
* Enter the command `hyperctl list`
```
[root@host1 ~]# hyperctl list
POD ID              POD Name            VM name             Status

< I have no pods running but details would appear here. Will update this FAQ once I have a better example >
[root@host1 ~]#
```
