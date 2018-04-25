#
# Cookbook:: redis
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.
docker_service 'default' do
  action [:create, :start]
end

docker_image 'redis' do
  action :pull
end
