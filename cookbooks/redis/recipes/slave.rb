#
# Cookbook:: redis
# Recipe:: slave
#
# Copyright:: 2018, The Authors, All Rights Reserved.
include_recipe 'redis::default'
docker_container 'redis-slave' do
  repo 'redis'
  port ['6379:6379', '26379:26379']
  restart_policy 'always'
  command "redis-server"
end
