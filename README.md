# Ejabberd metrics for Prometheus

Compile:

    erlc mod_prometheus.erl

Copy compiled file to ejabberd, for example:

    cp mod_prometheus.erl /opt/ejabberd-17.07/lib/ejabberd-17.07/ebin/

Add config to `ejabberd.yml`:

    listen:
      -
        port: 8181
        module: ejabberd_http
        request_handlers:
          "/": mod_prometheus

After this, restart ejabberd and try open `http://localhost:8181/metrics`
in browser. You have to see metrics for prometheus.

Service will responde all requests independently request type
and request path.
