

def run(plan, 
        prometheus_url, 
        grafana_dashboards_directory_path, 
        grafana_dashboards_name="Grafana Dashboards in Kurtosis"):
        """Runs provided Grafana dashboards in Kurtosis.

        Args:
            prometheus_url(string): Prometheus endpoint that will populate Grafana dashboard data.
            grafana_dashboards_directory_path(string): Where to find Grafana dashboards config.
            grafana_dashboards_name(string): Name of Grafana Dashboard provider.
        """



        plan.add_service(name="grafana", config=ServiceConfig(
            image="grafana/grafana-enterprise:9.5.12",
            ports={
                "http": PortSpec(
                    number=3000,
                    transport_protocol="TCP",
                    application_protocol="http",
                )
            },
            env_vars={
                "GF_AUTH_ANONYMOUS_ENABLED": "true",
                "GF_AUTH_ANONYMOUS_ORG_ROLE": "Admin",
                "GF_AUTH_ANONYMOUS_ORG_NAME": "Main Org.",
                "GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH": "/dashboards/default.json",
            },
            files={
            }
        ))