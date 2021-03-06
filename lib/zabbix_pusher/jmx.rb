#
# Author:: Edmund Haselwanter (<office@iteh.at>)
# Copyright:: Copyright (c) 2011 Edmund Haselwanter
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'httparty'

module ZabbixPusher

  class Jmx

    include HTTParty
    base_uri 'http://localhost:8080'
    format :json

    def initialize(items=[] ,options={})
      self.class.base_uri options[:base_uri] if options[:base_uri]
      @payload = Array.new
      @items = items
      @items.each do |item|  mbean,attribute,path = item.split(';')
        tokens = { "mbean" => mbean, "attribute" => attribute, "type" => "READ"}
        tokens["path"] = path if path
        @payload  << tokens
      end
    end

    # http://www.jolokia.org/reference/html/protocol.html#search

    def search(mbean,config={})
      self.class.post('/jolokia', :body => { "type" => "SEARCH", "mbean" => mbean, "config" => config}.to_json)
    end

    # http://www.jolokia.org/reference/html/protocol.html#list
    # use options = { "maxDepth" => 2} to limit depth

    def list(path,config={})
      self.class.post('/jolokia', :body => { "type" => "LIST", "path" => path, "config" => config}.to_json)
    end

    def read(mbean,attribute,path=nil,config={})
      payload = { "type" => "READ", "mbean" => mbean, "attribute" => attribute}
      payload["path"] = path if path
      payload["config"] = config if config.length > 0
      ap payload.to_json
      self.class.post('/jolokia', :body => payload.to_json, :timeout => 5)
    end

    def version
      self.class.post('/jolokia', :body => { "type" => "VERSION"}.to_json)
    end

    def processed_items
      data = self.class.post('/jolokia', :body => @payload.to_json, :timeout => 5) rescue nil
      result = Hash.new
      data.each{|datum| result[result_key(datum)] = datum['value'] if datum['request']} if data
      result
    end

    private

    def result_key(datum)
      "#{self.class.to_s.demodulize.underscore}[#{datum['request']['mbean']};#{datum['request']['attribute']};#{datum['request']['path']}]"
    end
  end

end