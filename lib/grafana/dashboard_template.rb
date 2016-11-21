
module Grafana

  module DashboardTemplate

    # CloudWatch Namespaces, Dimensions and Metrics Reference:
    # http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/CW_Support_For_AWS.html
    @@cw_dimensions = []


    def build_template(params={})


      params.fetch('from', 'now-2h')
      params.fetch('refresh', '15m')
      params.fetch('to', 'now')
      params.fetch('timezone', 'utc')
      params.fetch('id', 'null')

      overwrite = 'true'
      if params['id'] == 'null'
        overwrite = 'false'
      end

      if params['title'] == ''
        return false
      end

      rows = []
      params['rows'].each do |row|
        logger.info "Building row #{row}"
        rows.push(self.build_row(row))
      end

      tpl = %q[
      {
        "dashboard": {
          "id": %{id},
          "title": "%{title}",
          "originalTitle": "%{title}",
          "annotations": {
            "list": []
          },
          "hideControls": false,
          "timezone": "browser",
          "editable": true,
          "rows": [
            %{rows}
          ],
          "time": {
            "from": "%{from}",
            "to": "%{to}"
          },
          "timepicker": {
            "collapse": false,
            "enable": true,
            "notice": false,
            "now": true,
            "refresh_intervals": [
              "5s",
              "10s",
              "30s",
              "1m",
              "5m",
              "15m",
              "30m",
              "1h",
              "2h",
              "1d"
            ],
            "status": "Stable",
            "time_options": [
              "5m",
              "15m",
              "1h",
              "6h",
              "12h",
              "24h",
              "2d",
              "7d",
              "30d"
            ],
            "type": "timepicker"
          },
          "tags": ["api-templated"],
          "templating": {
            "list": []
          },
          "schemaVersion": 7,
          "sharedCrosshair": false,
          "style": "dark",
          "version": 1,
          "refresh": "%{refresh}",
          "links": []
        },
        "overwrite": %{overwrite}
      }
      ]

      return tpl % {
          title: params['title'],
          from: params['from'],
          to: params['to'],
          utc: params['utc'],
          id: params['id'],
          refresh: params['refresh'],
          overwrite: overwrite,
          rows: rows.join(',')
      }

    end


    def build_row(params={})

      row = %q[
        {
          "collapse": false,
          "editable": true,
          "height": "250px",
          "panels": [%{panels}],
          "showTitle": true,
          "title": "%{title}"
        }
      ]

      panels = []
      params.fetch('panels', []).each do |t|
        logger.info "Building panel #{t}"
        panels.push(self.build_panel(t))
      end

      return row % {
          panels: panels.join(','),
          title: params.fetch('title', 'Row')
      }


    end

    def build_panel(params={})

      panel = %q[
        %{type}
      ]

      graph_type = params.fetch('type', 'graph')
      type = nil
      if graph_type == 'graph'
        type = self.build_graph(params)
      elsif graph_type == 'singlestat'
        type = self.build_singlestat(params)
      end

      return panel % {
          type: type
      }

    end

    #build graph type
    def build_graph(params)
      graph_type = %q[
        {
          "aliasColors": {},
          "bars": false,
          "datasource": "%{datasource}",
          "editable": true,
          "error": false,
          "fill": 1,
          "grid": {
            "leftLogBase": 1,
            "leftMax": null,
            "leftMin": null,
            "rightLogBase": 1,
            "rightMax": null,
            "rightMin": null,
            "threshold1": null,
            "threshold1Color": "rgba(216, 200, 27, 0.27)",
            "threshold2": null,
            "threshold2Color": "rgba(234, 112, 112, 0.22)"
          },
          "id": %{id},
          "isNew": true,
          "legend": {
            "alignAsTable": true,
            "avg": false,
            "current": true,
            "max": true,
            "min": true,
            "show": true,
            "total": false,
            "values": true
          },
          "lines": true,
          "linewidth": 2,
          "links": [],
          "nullPointMode": "connected",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "span": %{span},
          "stack": false,
          "steppedLine": false,
          "targets": [
            %{targets}
          ],
          "timeFrom": null,
          "timeShift": null,
          "title": "%{graph_title}",
          "tooltip": {
            "shared": true,
            "value_type": "cumulative"
          },
          "type": "graph",
          "x-axis": true,
          "y-axis": true,
          "y_formats": [
            "short",
            "short"
          ]
        }
      ]

      targets = []
      params.fetch('targets', []).each do |t|
        targets.push(self.build_target(t))
      end

      return graph_type % {
          datasource: params['datasource'],
          graph_title: params['graph_title'],
          id: params.fetch('id', '1'),
          span: params.fetch('span', 4), # defines how many panels per row.. 12 means 1 panel per row, 4 means 3 panels per row
          targets: targets.join(','),
      }
    end

    def build_singlestat(params)

      graph_type = %q[
        {
          "cacheTimeout": null,
          "colorBackground": true,
          "colorValue": false,
          "colors": [
            "rgba(50, 172, 45, 0.97)",
            "rgba(237, 129, 40, 0.89)",
            "rgba(245, 54, 54, 0.9)"
          ],
          "datasource": "%{datasource}",
          "editable": true,
          "error": false,
          "format": "none",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "id": %{id},
          "interval": null,
          "isNew": true,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": " seconds",
          "postfixFontSize": "50",
          "prefix": "Latency",
          "prefixFontSize": "50",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "span": %{span},
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "targets": [
            %{targets}
          ],
          "thresholds": "%{threshold_min},%{threshold_max}",
          "title": "%{graph_title}",
          "type": "singlestat",
          "valueFontSize": "80",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        }
      ]

      targets = []
      params.fetch('targets', []).each do |t|
        targets.push(self.build_target(t))
      end

      puts graph_type

      return graph_type % {
          datasource: params['datasource'],
          graph_title: params['graph_title'],
          id: params.fetch('id', '1'),
          span: params.fetch('span', 4), # defines how many panels per row.. 12 means 1 panel per row, 4 means 3 panels per row
          targets: targets.join(','),
          threshold_min: params.fetch('threshold_min', 3),
          threshold_max: params.fetch('threshold_max', 7),
      }

    end

    def build_target(params={})

      target = %q[
        {
          "alias": "%{legend_alias}",
          "dimensions": {
            "%{dimension_name}": "%{dimension_value}"
          },
          "metricName": "%{metric_name}",
          "namespace": "%{namespace}",
          "period": 60,
          "query": "",
          "refId": "A",
          "region": "%{region}",
          "statistics": [
            "%{stats}"
          ],
          "timeField": "@timestamp"
        }
      ]

      return target % {
          metric_name: params['metric_name'],
          namespace: params['namespace'],
          dimension_name: params['dimension_name'],
          dimension_value: params['dimension_value'],
          region: params['region'],
          stats: params.fetch('stats', 'Maximum'),
          legend_alias: params['legend_alias'],
      }

    end

  end

end
