### Instalation

Require `mysqldump` and `jq`.

`jq` install instruction can be found [here](https://stedolan.github.io/jq/download/).

For CentOS:

```bash
wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
chmod +x ./jq
cp jq /usr/bin
```

Clone the repo: 

```bash
git clone https://github.com/ownego/database-backup.git
```

Then start to config:

```bash
cd database-backup
bash oe_db.sh -c
```

### Usage

This script take 3 options:

`-c` to config database connections.

`-a` to run backup progress for all databases defined in config file.

`-b database_name` to run backup progress for one specific database (must be defined in config).

Each database config entry has 4 properties:

   *   Database name
   *   Database username
   *   Database password
   *   Database backup cycle
    

### Crontab usage

Examples:

```bash
00 00 * * * bash /path/to/oe_db.sh -a
00 12 * * * bash /path/to/oe_db.sh -d example_database
```

