# CLI commands

List of commands that are rarely used and are here for quick lookup

## Storage clean up

Remove archived journal files until the disk space they use falls below 100M:

```sh
journalctl --vacuum-size=100M
```

Make all journal files contain no data older than 2 weeks.

```sh
journalctl --vacuum-time=2weeks
```

## Docker

Remove unnecessary images before

```sh
docker rmi $(sudo docker images --filter "dangling=true" -q --no-trunc)
```
