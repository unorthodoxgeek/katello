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
  class Api::V2::ContentViewFilterRulesController < Api::V2::ApiController

    before_filter :find_filter
    before_filter :find_rule, :except => [:index, :create]

    api :GET, "/content_view_filters/:content_view_filter_id/rules", "List filter rules"
    param :content_view_filter_id, :identifier, :desc => "filter identifier", :required => true
    def index
      options = sort_params
      options[:load_records?] = true
      options[:filters] = [{ :terms => { :id => ContentViewFilter.rule_ids_for(@filter) } }]

      @search_service.model = ContentViewFilter.rule_class_for(@filter)
      respond(:collection => item_search(ContentViewFilter.rule_class_for(@filter), params, options))
    end

    api :POST, "/content_view_filters/:content_view_filter_id/rules",
        "Create a filter rule. The parameters included should be based upon the filter type."
    param :content_view_filter_id, :identifier, :desc => "filter identifier", :required => true
    param :name, String, :desc => "package or package group: name"
    param :version, String, :desc => "package: version"
    param :min_version, String, :desc => "package: minimum version"
    param :max_version, String, :desc => "package: maximum version"
    param :errata_id, String, :desc => "erratum: id"
    param :start_date, String, :desc => "erratum: start date (YYYY-MM-DD)"
    param :end_date, String, :desc => "erratum: end date (YYYY-MM-DD)"
    param :types, Array, :desc => "erratum: types (enhancement, bugfix, security)"
    def create
      rule_clazz = ContentViewFilter.rule_class_for(@filter)
      rule = rule_clazz.create!(rule_params.merge(:filter => @filter))
      respond :resource => rule
    end

    api :GET, "/content_view_filters/:content_view_filter_id/rules/:id", "Show filter rule info"
    param :content_view_filter_id, :identifier, :desc => "filter identifier", :required => true
    param :id, :identifier, :desc => "rule identifier", :required => true
    def show
      respond :resource => @rule
    end

    api :PUT, "/content_view_filters/:content_view_filter_id/rules/:id",
        "Update a filter rule. The parameters included should be based upon the filter type."
    param :content_view_filter_id, :identifier, :desc => "filter identifier", :required => true
    param :id, :identifier, :desc => "rule identifier", :required => true
    param :name, String, :desc => "package or package group: name"
    param :version, String, :desc => "package: version"
    param :min_version, String, :desc => "package: minimum version"
    param :max_version, String, :desc => "package: maximum version"
    param :errata_id, String, :desc => "erratum: id"
    param :start_date, String, :desc => "erratum: start date (YYYY-MM-DD)"
    param :end_date, String, :desc => "erratum: end date (YYYY-MM-DD)"
    param :types, Array, :desc => "erratum: types (enhancement, bugfix, security)"
    def update
      @rule.update_attributes!(rule_params)
      respond :resource => @rule
    end

    api :DELETE, "/content_view_filters/:content_view_filter_id/rules/:id", "Delete a filter rule"
    param :content_view_filter_id, :identifier, :desc => "filter identifier", :required => true
    param :id, :identifier, :desc => "rule identifier", :required => true
    def destroy
      @rule.destroy
      respond_for_show :resource => @rule
    end

    private

    def find_filter
      @filter = ContentViewFilter.find(params[:content_view_filter_id])
      fail HttpErrors::Forbidden, _("You cannot access ContentViewFilter with id=%s") % params[:content_view_filter_id] unless @filter.content_view.readable?
    end

    def find_rule
      rule_clazz = ContentViewFilter.rule_class_for(@filter)
      @rule = rule_clazz.find(params[:id])
    end

    def rule_params
      params.require(:content_view_filter_rule).permit(:name, :version, :min_version, :max_version,
                                                       :errata_id, :start_date, :end_date, :types => [])
    end

  end
end
