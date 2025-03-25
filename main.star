CONFIG_DIR_PATH = "/config"
DASHBOARDS_DIR_PATH = "/dashboards"


def run(
    plan,
    prometheus_url,
    grafana_dashboards_location="",
    name="grafana",
    grafana_dashboards_name="Grafana Dashboards in Kurtosis",
    grafana_version="9.5.12",
    grafana_alerting_template="",
    grafana_alerting_data={},
    postgres_databases=[],
    grafana_dashboards_files_artifact="",
):
    """Runs provided Grafana dashboards in Kurtosis.

    Args:
        prometheus_url (string): Prometheus endpoint that will populate Grafana dashboard data.
        grafana_dashboards_location (string, optional): Where to find config for Grafana dashboard(s) (usually sitting somewhere in the repo that's importing this package). Setting this will override grafana_dashboards_files_artifact.
        grafana_dashboards_name (string, optional): Name of Grafana Dashboard provider.
        grafana_version (string, optional): The version of grafana to use.
        grafana_alerting_template (string, optional): Path to the Grafana alerting template file (usually sitting somewhere in the repo that's importing this package).
        grafana_alerting_data (dict[string, string], optional): The data used for templating the grafana_alerting_template.
        postgres_databases (list[dict[string, string]], optional): The data used for templating the Postgres Grafana data source(s).
        grafana_dashboards_files_artifact (string, optional): The dashboards files artifact, this will be overridden by grafana_dashboards_location if it's set.
    """

    # create config files artifacts based on datasource and dashboard providers info
    datasource_config_template = read_file(src="./static-files/datasource.yml.tmpl")
    dashboard_provider_config_template = read_file(
        src="./static-files/dashboard-providers.yml.tmpl"
    )

    grafana_render_templates_config = {
        "datasources/datasource.yml": struct(
            template=datasource_config_template,
            data={
                "PrometheusURL": prometheus_url,
                "PostgresDatabases": postgres_databases,
            },
        ),
        "dashboards/dashboard-providers.yml": struct(
            template=dashboard_provider_config_template,
            data={
                "DashboardProviderName": grafana_dashboards_name,
                "DashboardsDirpath": DASHBOARDS_DIR_PATH,
            },
        ),
    }

    if grafana_alerting_template != "":
        grafana_render_templates_config["alerting/alerting.yml"] = struct(
            template=read_file(grafana_alerting_template),
            data=grafana_alerting_data,
        )

    grafana_config_files_artifact = plan.render_templates(
        config=grafana_render_templates_config,
    )

    if grafana_dashboards_location != "":
        # grab grafana dashboards from given location and upload them into enclave as a files artifact
        grafana_dashboards_files_artifact = plan.upload_files(
            src=grafana_dashboards_location, name="grafana-dashboards"
        )

    files = {CONFIG_DIR_PATH: grafana_config_files_artifact}

    if grafana_dashboards_files_artifact != "":
        files[DASHBOARDS_DIR_PATH] = grafana_dashboards_files_artifact

    plan.add_service(
        name=name,
        config=ServiceConfig(
            image="grafana/grafana-enterprise:" + grafana_version,
            ports={
                "dashboards": PortSpec(
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
            files=files,
        ),
    )
