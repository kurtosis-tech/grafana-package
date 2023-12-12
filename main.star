CONFIG_DIR_PATH="/config"
DASHBOARDS_DIR_PATH="/dashboards"

def run(plan, 
        prometheus_url, 
        grafana_dashboards_directory_path, 
        grafana_dashboards_name="Grafana Dashboards in Kurtosis"):
        """Runs provided Grafana dashboards in Kurtosis.

        Args:
            prometheus_url(string): Prometheus endpoint that will populate Grafana dashboard data.
            grafana_dashboards_directory_path(string): Where to find Grafana dashboards config (usually sitting somewhere repo of that's importing this package))
            grafana_dashboards_name(string): Name of Grafana Dashboard provider.
        """

        # create config files artifacts based on datasource and dashboard providers info
        datasource_config_template = read_file(src="./static-files/datasource.yml.tmpl")
        dashboard_provider_config_template = read_file(src="./static-files/dashboard-providers.yml.tmpl")
        grafana_config_files_artifact = plan.render_templates(
            config={
                "datasources/datasource.yml":struct(
                    template=datasource_config_template,
                    data={ "PrometheusURL": prometheus_url }
                ),
                "dashboards/dashboard-providers.yml":struct(
                    template=dashboard_provider_config_template,
                    data={
                        "DashboardProviderName": grafana_dashboards_name,
                        "DashboardsDirpath": grafana_dashboards_directory_path,
                    }
                ),
            }
        )

        # upload grafana dashboards from given path
        grafana_dashboards_files_artifact = plan.upload_files(src=grafana_dashboards_directory_path, name="grafana-dashboards")

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
                "GF_PATHS_PROVISIONING": CONFIG_DIR_PATH,
                "GF_AUTH_ANONYMOUS_ENABLED": "true",
                "GF_AUTH_ANONYMOUS_ORG_ROLE": "Admin",
                "GF_AUTH_ANONYMOUS_ORG_NAME": "Main Org.",
            },
            files={
                CONFIG_DIR_PATH: grafana_config_files_artifact,
                DASHBOARDS_DIR_PATH: grafana_dashboards_files_artifact,
            }
        ))
