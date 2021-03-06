#
# Copyright 2014 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

module Katello
module Glue::Pulp::Distribution
  def self.included(base)
    base.send :include, InstanceMethods

    base.class_eval do
      attr_accessor :_id, :id, :description, :files, :family, :variant, :version, :url, :arch, :repoids

      def self.find(id)
        Katello::Distribution.new(Katello.pulp_server.extensions.distribution.find(id))
      end
    end
  end

  module InstanceMethods

    def initialize(attrs = {}, options = {})
      attrs[:repoids] = attrs.delete(:repository_memberships)
      generate_instance_variables(attrs)
    end

    def generate_instance_variables(attrs)
      attrs.each_pair do |k, v|
        if self.class.method_defined?(k) && !v.nil?
          instance_variable_set("@#{k}", v)
        end
      end
    end

    def as_json(*args)
      result = super(*args)
      result['files'] = result['files'].inject([]) do |paths, file|
        paths << file['relativepath']
      end
      result
    end

  end
end
end
