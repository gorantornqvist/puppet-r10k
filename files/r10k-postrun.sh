#!/bin/bash
# r10k-postrun-environments.sh: Managed by puppet
# This script is executed by r10k as a post command

configfile=$(dirname $(realpath $0))/r10k-postrun.conf
if [ -f "$configfile" ]; then
  . $configfile
else
  echo "Missing config file $configfile, example config:
rsync_hosts='host1 host2'
r10k_basedir=/etc/puppet/r10k
log=/var/log/webhook/r10k-postrun.log
hammer_config=/root/.hammer/cli_config.yml
organization=pm
environments_dir=/etc/puppet/r10k/environments
"
  exit 1
fi

deploy_type=$1

# disable proxy if set since we will run hammer
http_proxy=""
ftp_proxy=""
https_proxy=""

echo "Start post run script at $(date)" >>$log

if [ "$deploy_type" == "module" ]; then
  echo "Deploy type: module ..." >>$log
else
  echo "Deploy type: environment ..." >>$log

  echo "Querying satellite for puppet environments ..." >>$log
  json_envs=$(hammer --output json -c $hammer_config environment list 2>>$log)
  if [ "$?" -ne "0" ]; then
    echo "ERROR - Problem querying Satellite for puppet environments ..." >>$log
    echo "$json_envs" >>$log
  else
    echo "Verifying that each puppet environment dir in $environments_dir exists as an environment in satellite ..." >>$log
    for r10k_env in $(ls -1 $environments_dir/); do
      if ! echo $json_envs | jgrep -s "Name" | grep -q "^${r10k_env}$" ; then
        echo "Creating new puppet environment $r10k_env in Satellite ..." >>$log
        hammer -c $hammer_config environment create --name "$r10k_env" --organizations "$organization" >>$log 2>&1
        if [ "$?" -ne "0" ]; then
          echo "ERROR - Problem creating puppet environment $r10k_env in Satellite ..." >>$log
        else
          # Enable if you use Satellite for configuring classes, leave commented out if you use Hiera
          #hammer -c $hammer_config proxy import-classes --id 1 --environment $r10k_env
        fi
      fi
    done
  fi
fi

echo "Rsyncing /etc/puppet/r10k to hosts: $rsync_hosts ..." >>$log
for rsync_host in $rsync_hosts; do
  echo "Rsyncing to host $rsync_host ..." >>$log 2>&1
  rsync -av $rsync_options --delete --exclude='.git/' --exclude='.r10k-deploy.json' $r10k_basedir/ $rsync_host:$r10k_basedir >>$log 2>&1
  if [ "$?" -ne "0" ]; then
    echo "ERROR - Problem rsyncing to host $rsync_host ..." >>$log
  fi
done

echo "End post run script at $(date)" >>$log

