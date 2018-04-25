#
# Cookbook:: redis
# Recipe:: master
#
# Copyright:: 2018, The Authors, All Rights Reserved.
include_recipe 'redis::default'
docker_container 'redis-master' do
  repo 'redis'
  port '6379:6379'
  restart_policy 'always'
  command "redis-server"
end
