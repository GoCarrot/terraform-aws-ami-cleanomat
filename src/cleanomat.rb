# frozen_string_literal: true

# Copyright 2021 Teak.io, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'aws-sdk-ec2'

module Cleanomat
  class Cleanomat
    attr_reader :cutoff, :credentials, :worker_count, :client, :logger

    def initialize(retain_count:, retain_days:, credentials: nil, workers: 10, logger: nil)
      @logger = logger
      @clear_range = (0...-retain_count)
      @cutoff = (Time.now - retain_days * 86400).strftime("%Y-%m-%dT%H:%M:%S.000Z")
      @retain_days = retain_days
      @queue = Queue.new

      client_init_opts =
        if credentials
          { credentials: credentials, logger: logger }
        else
          { logger: logger }
        end
      @client = Aws::EC2::Client.new(client_init_opts)

      @workers = workers.times.map do
        Thread.new do
          while image = @queue.pop
            @logger&.info("Deregistring #{image.name}")
            @client.deregister_image(image_id: image.image_id)

            snapshots = image.block_device_mappings.lazy.map(&:ebs).map(&:snapshot_id).to_a
            snapshots.each do |snap|
              @logger&.info("Deleting snapshot #{snap}")
              @client.delete_snapshot(snapshot_id: snap)
            end
          end
        end
      end
    end

    def call
      images = client.describe_images(owners: ['self']).images
      images.sort_by!(&:creation_date)
      groups = images.each_with_object({}) do |image, hash|
        name = image.name
        prefix = name.slice(0, name.index('.'))
        hash[prefix] ||= []
        hash[prefix] << image
      end

      to_delete = groups.each_value.each_with_object([]) do |list, arr|
        list = list[@clear_range]
        list.select! { |image| image.creation_date <= @cutoff }

        arr.push(list)
      end
      to_delete.flatten!
      to_delete.each { |image| @queue.push(image) }
      @queue.close
      @workers.each(&:join)
      to_delete.map(&:name)
    end
  end
end
