Grafana Package
============
This is a Grafana [Kurtosis](https://github.com/kurtosis-tech/kurtosis/) Grafpackage. Provided a Prometheus datasource and dashboard configuration files, it will spin up a Grafana instance for you!

Run this package
----------------
If you have [Kurtosis installed][install-kurtosis], run:

```bash
kurtosis run github.com/kurtosis-tech/grafana-package --args-file args.json
```

If you don't have Kurtosis installed, [click here to run this package on the Kurtosis playground](https://gitpod.io/?autoStart=true&editor=code#https://github.com/kurtosis-tech/playground-gitpod).

To blow away the created [enclave][enclaves-reference], run `kurtosis clean -a`.

#### Configuration

<details>
    <summary>Click to see configuration</summary>

You can configure this package using the JSON structure below. The default values for each parameter are shown.

NOTE: the `//` lines are not valid JSON; you will need to remove them!

```javascript
{
    // URL of running Prometheus instance that will populate dashboards
    "prometheus_url": "'",

    // Path to Grafana dashboard configurations (usually sitting in repo of the script thats importing this package))
    "grafana_dashboards_directory_path": "",

    // Name for Grafana Dashboard Provider
    // Optional
    "grafana_dashboards_name":"Kurtosis Grafana Dashboards",

}
```

The arguments can then be passed in to `kurtosis run`.

For example:

```bash
kurtosis run github.com/kurtosis-tech/grafana-package '{"prometheus_url":"127.0.0.1:9090", "grafana_dashboards_directory_path:"../static-files/dashboards/"}'
```

You can also store the JSON args in a file, and use command expansion to slot them in:

```bash
kurtosis run github.com/kurtosis-tech/grafana-package --args-file args.json"
```

</details>

Use this package in your package
--------------------------------
Kurtosis packages can be composed inside other Kurtosis packages. To use this package in your package:

First, import this package by adding the following to the top of your Starlark file:
Then, call the this package's `run` function somewhere in your Starlark script:

```python
# For remote packages: 
grafana = import_module("github.com/kurtosis-tech/grafana-package/main.star") 

# For local packages:
this_package = import_module(".src/main.star")

def run(plan, args={}):
    # add a service that exposes a metrics port for prometheus metrics
    service_a = plan.add_service(name="sevice_a", config=ServiceConfig(
        ...
        ports = {
            "metrics": PortSpec(number=9090, transport_protocol="TCP", application_protocol="http")
        },
        ...
    ))

    service_a_metrics_job = { 
        "Name":"service_a", 
        "Endpoint":"http://{0}:{1}".format(service_a.ip_address, service_a.ports["metrics"].number),
        "Labels": { 
            "service_type": "backend" 
        }
    }

    # start a prometheus server that scrapes service_a's metrics and returns a prom url for querying those metrics
    prometheus_url = prometheus-package.run(plan, [service_a_metrics_job])

    # start grafana where dashboards are located at ../static-files/dashboards relative to script
    grafana.run(plan, prometheus_url, "../static-files/dashboards")
```

If you want to use a fork or specific version of this package in your own package, you can replace the dependencies in your `kurtosis.yml` file using the [replace](https://docs.kurtosis.com/concepts-reference/kurtosis-yml/#replace) primitive. 
Within your `kurtosis.yml` file:
```python
name: github.com/example-org/example-repo
replace:
    github.com/kurtosis-tech/grafana-package: github.com/YOURUSER/THISREPO@YOURBRANCH
```

Develop on this package
-----------------------
1. [Install Kurtosis][install-kurtosis]
1. Clone this repo
1. For your dev loop, run `kurtosis clean -a && kurtosis run .` inside the repo directory


<!-------------------------------- LINKS ------------------------------->
[install-kurtosis]: https://docs.kurtosis.com/install
[enclaves-reference]: https://docs.kurtosis.com/concepts-reference/enclaves
