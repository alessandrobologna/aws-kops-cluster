FROM fluent/fluentd:v0.12-onbuild


RUN apk add --update --virtual .build-deps \
        sudo build-base ruby-dev \
 && sudo gem install \
        fluent-plugin-secure-forward fluent-plugin-record-reformer fluent-plugin-parser fluent-plugin-grep \
        fluent-plugin-json-transform fluent-plugin-kubernetes_metadata_filter fluent-plugin-dogstatsd \
 && sudo gem sources --clear-all \
 && apk del .build-deps \
 && rm -rf /var/cache/apk/* \
           /home/fluent/.gem/ruby/2.3.0/cache/*.gem

# Copy configuration files
COPY fluent.conf /fluentd/etc/

# Override entrypoint
COPY entrypoint.sh /bin/
RUN chmod +x /bin/entrypoint.sh


# Environment variables
ENV FLUENTD_CONF="fluent.conf"

# jemalloc is memory optimization only available for td-agent
# td-agent is provided and QA'ed by treasuredata as rpm/deb/.. package
# -> td-agent (stable) vs fluentd (edge)
#ENV LD_PRELOAD="/usr/lib/libjemalloc.so.2"

# Run Fluentd
CMD exec fluentd -c /fluentd/etc/$FLUENTD_CONF -p /fluentd/plugins $FLUENTD_OPT