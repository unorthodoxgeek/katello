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
  class Api::V2::ContentViewVersionsController < Api::V2::ApiController
    before_filter :find_content_view_version, :only => [:show, :promote, :destroy]

    api :GET, "/content_view_versions", "List content view versions"
    api :GET, "/content_views/:content_view_id/content_view_versions", "List content view versions"
    param :content_view_id, :identifier, :desc => "Content view identifier", :required => true
    def index
      collection = {:results  => @view.versions.order('version desc'),
                    :subtotal => @view.versions.count,
                    :total    => @view.versions.count
                   }
      respond(:collection => collection)
    end

    api :GET, "/content_view_versions/:id", "Show content view version"
    param :id, :identifier, :desc => "Content view version identifier", :required => true
    def show
      @version = ContentViewVersion.readable.find(params[:id])
      respond :resource => @version
    end

    api :POST, "/content_view_versions/:id/promote", "Promote a content view version"
    param :id, :identifier, :desc => "Content view version identifier", :required => true
    param :environment_id, :identifier
    def promote
      # TODO: update with partha's delete/promote work
      @version = ContentViewVersion.readable.find(params[:id])
      @environment = KTEnvironment.readable.find(params[:environment_id])
      task = async_task(::Actions::Katello::ContentView::Promote, @version, @environment)
      respond_for_async :resource => task
    end

    api :DELETE, "/content_view_versions/:id", "Remove content view version"
    param :id, :identifier, :desc => "Content view version identifier", :required => true
    def destroy
      @version = ContentViewVersion.deletable.find(params[:id])
      task = async_task(::Actions::Katello::ContentViewVersion::Destroy, @version)
      respond_for_async :resource => task
    end

  end
end
