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
- curl
- jq
- bash
- Node Exporter with textprom enabled, e.g. `--collector.textfile.directory=/host/somewhere/node_exporter/textprom/` in your docker command with a mount for `/host`, [read this for details](https://github.com/prometheus/node_exporter#textfile-collector)

# How

1. Get rated.network account and create API key
2. Edit script and insert API key in top
3. Run script, if output looks sane, add to cron.

NOTE: Be sure to output to separate files if you want to run hourly/daily/monthly at the same time.

Example crontab -e entry
```
# Run hourly job at 55 minutes past the hour
55 * * * * /path/to/node-raver.sh hourly > /path/to/node_exporter/textprom/raver-hourly.txt
# Run daily job at 1:55
45 1 * * * /path/to/node-raver.sh daily > /path/to/node_exporter/textprom/raver-daily.txt
```

# Result

# You blew up my machine

Pretty sure that was you.

In other words:
No warranty, please read through the script and understand it (at least in broad strokes) before running it.
It works for me (tm), also feel free to fork/copy/clone/adjust as you see fit!

Note that by default you get 100000 API requests on a free account. This script uses 1 per execution.
If you run it once every hour on hourly, once per day for daily, etc, it result in <1K calls per month.
