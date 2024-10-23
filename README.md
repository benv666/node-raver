# What

"Simple" bash script to put into a crontab on a machine running Node Exporter.

# Why

To pull Rated.Network's [Rated Effectiveness Rating](https://docs.rated.network/methodologies/ethereum/rated-effectiveness-rating) aka Raver score and put it into prometheus.

# Why

To be able to see your network rating locally

# Why

So you can have prometheus/grafana alert on them

# Why

Pretty graphs ;)

# Requirements

- Rated.network API key
- bash
- curl
- jq
- Node Exporter with textprom enabled, e.g. `--collector.textfile.directory=/host/somewhere/node_exporter/textprom/` in your docker command with a mount for `/host`, [read this for details](https://github.com/prometheus/node_exporter#textfile-collector)
- A working cron implementation

# How

1. Get rated.network account and create API key
2. Edit script and insert API key in top
3. Run script, if output looks sane, add to cron.

NOTE: Be sure to output to separate files if you want to run hourly/daily/monthly at the same time.

Example crontab -e entry
```
# Run hourly job at 55 minutes past the hour
55 * * * * /path/to/node-raver.sh hourly > /path/to/node_exporter/textprom/raver-hourly.prom
# Run daily job at 1:55
45 1 * * * /path/to/node-raver.sh daily > /path/to/node_exporter/textprom/raver-daily.prom
```

# Result

When setup correctly, you should see /path/to/node_exporter/textprom/raver-hourly.prom appear.
If not, check permissions and cron logs, (cron should send emails on failures).
Once this file is present and Node Exporter has been told to enable the textfile directory collector to this path,
new metrics such as `rated_avg_attester_effectiveness` should appear.

You can make pretty graphs:

![Raver Panel in Grafana](docs/raver-panel.png?raw=true "Grafana Example Raver Panel")

And alert on them. In case of grafana, hit the dots in the top right corner, More => Alert Rule:
![Raver Alert Rule in Grafana](docs/raver-alert.png?raw=true "Grafana Create Alert Rule")
- only query what you want to alert on (e.g. `rated_avg_attester_effectiveness{range="1d"}`)
- set a proper treshold (alert fires when it goes below 95 in this example)
- make sure the notification goes somewhere, like the rest of your grafana alerts.

# You blew up my machine

Pretty sure that was you.

In other words:
No warranty, please read through the script and understand it (at least in broad strokes) before running it.
It works for me (tm), also feel free to fork/copy/clone/adjust as you see fit!

Note that by default you get 100000 API requests on a free account. This script uses 1 per execution.
If you run it once every hour on hourly, once per day for daily, etc, it result in <1K calls per month.
