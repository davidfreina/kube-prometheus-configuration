local update_intervals = {
  kubernetesControlPlane+: {
    serviceMonitorKubeScheduler+: {
      spec+: {
        endpoints: std.map(
          function(endpoint)
            endpoint {
              interval: '5s',
            },
          super.endpoints
        ),
      },
    },
    serviceMonitorKubelet+: {
      spec+: {
        endpoints: std.map(
          function(endpoint)
            endpoint {
              interval: '1s',
            },
          super.endpoints
        ),
      },
    },
    serviceMonitorKubeControllerManager+: {
      spec+: {
        endpoints: std.map(
          function(endpoint)
            endpoint {
              interval: '5s',
            },
          super.endpoints
        ),
      },
    },
    serviceMonitorApiserver+: {
      spec+: {
        endpoints: std.map(
          function(endpoint)
            endpoint {
              interval: '5s',
            },
          super.endpoints
        ),
      },
    },
  }
};

local kp = (import 'kube-prometheus/main.libsonnet') + update_intervals;
local kp = (import 'kube-prometheus/main.libsonnet') +
           update_intervals + {
  values+:: {
    common+: {
      namespace: 'monitoring',
    },
    prometheus+: {
      namespaces+: ['openfaas', 'openfaas-fn'],
    },
    grafana+: {
      dashboards:: {
        'function-dashboard.json': (import 'function-dashboard.json'),
        'logs-dashboard.json': (import 'logs-dashboard.json'),
      },
      config+: {
        sections+: {
          dashboards: { min_refresh_interval: '1s' }
        }
      },
      datasources: [
          {
            name: 'prometheus',
            type: 'prometheus',
            access: 'proxy',
            orgId: 1,
            url: 'http://prometheus-k8s.' + $.values.common.namespace + '.svc:9090',
            version: 1,
            editable: false,
          },
          {
            name: 'loki',
            type: 'loki',
            access: 'proxy',
            orgId: 1,
            url: 'http://loki-stack-headless.' + $.values.common.namespace + '.svc:3100',
            version: 1,
            editable: false,
          },
      ],
    },
  },
};
{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
