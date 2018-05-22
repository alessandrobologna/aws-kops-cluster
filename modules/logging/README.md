## Fluentd/CloudWatch logging

This directory implements a fluentd based logging architecture for kubernetes that sends all logs to cloudwatch.
The naming schema for the logs is:

- LogGroup:  `/kube/<cluster>/namespace`
- LogStream: `<pod-name>/<container-name>`

### Deployment
Just run `make deploy` after making sure that your kubectl context is set to the right cluster.


