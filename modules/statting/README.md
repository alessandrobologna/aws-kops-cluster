## FluentD/StatsD integration

This directory contains the implementation for a daemonset deployment that collects logs from each pod in the cluster, and forwards the extracted metric values to StatsD

### Deployment
Just run `make deploy` after making sure that your kubectl context is set to the right cluster.
