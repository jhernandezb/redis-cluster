#
# Cookbook:: redis
# Recipe:: sentinel
#
# Copyright:: 2018, The Authors, All Rights Reserved.
include_recipe 'redis::default'
docker_container 'redis-sentinel' do
  repo 'redis'
  port ['26379:26379']
  restart_policy 'always'
  volumes '/etc/redis/sentinel.conf:/etc/redis/sentinel.conf'
  command "redis-server /etc/redis/sentinel.conf --sentinel"
end
