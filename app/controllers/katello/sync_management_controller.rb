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

# rubocop:disable ClassVars
module Katello
class SyncManagementController < Katello::ApplicationController
  include TranslationHelper
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper
  include SyncManagementHelper::RepoMethods
  respond_to :html, :json

  # to avoid problems when generating Headpin documenation when
  # building RPMs
  if Katello.config.use_pulp
    @@status_values = { PulpSyncStatus::Status::WAITING => _("Queued."),
                        PulpSyncStatus::Status::FINISHED => _("Sync complete."),
                        PulpSyncStatus::Status::ERROR => _("Error syncing!"),
                        PulpSyncStatus::Status::RUNNING => _("Running."),
                        PulpSyncStatus::Status::CANCELED => _("Canceled."),
                        PulpSyncStatus::Status::NOT_SYNCED => ""}
  else
    @@status_values = {}
  end

  def section_id
    'contents'
  end

  def title
    _('Sync Status')
  end

  def index
    org = current_organization
    @products = org.library.products.readable
    redhat_products, custom_products = @products.partition(&:redhat?)
    redhat_products.sort_by { |p| p.name.downcase }
    custom_products.sort_by { |p| p.name.downcase }

    @products = redhat_products + custom_products
    @product_size = {}
    @repo_status = {}
    @product_map = collect_repos(@products, org.library, false)

    @products.each { |product| get_product_info(product) }
  end

  def sync
    ids = sync_repos(params[:repoids]) || {}
    render :json => ids.to_json
  end

  def sync_status
    collected = []
    repos = Repository.where(:id => params[:repoids]).readable
    repos.each do |repo|
      begin
        progress = format_sync_progress(repo.sync_status, repo)
        collected.push(progress)
      rescue ActiveRecord::RecordNotFound => e
        notify.exception e # debugging and skip for now
        next
      end
    end

    render :json => collected.to_json
  end

  def destroy
    Repository.find(params[:id]).cancel_sync
    render :text => ""
  end

  private

  def format_sync_progress(sync_status, repo)
    progress = sync_status.progress
    error_details = progress.error_details

    not_running_states = [PulpSyncStatus::Status::FINISHED,
                          PulpSyncStatus::Status::ERROR,
                          PulpSyncStatus::Status::WAITING,
                          PulpSyncStatus::Status::CANCELED,
                          PulpSyncStatus::Status::NOT_SYNCED]
    {   :id             => repo.id,
        :product_id     => repo.product.id,
        :progress       => calc_progress(sync_status, repo.content_type),
        :sync_id        => sync_status.uuid,
        :state          => format_state(sync_status.state),
        :raw_state      => sync_status.state,
        :start_time     => format_date(sync_status.start_time),
        :finish_time    => format_date(sync_status.finish_time),
        :duration       => format_duration(sync_status.finish_time, sync_status.start_time),
        :packages       => sync_status.progress.total_count,
        :display_size   => number_to_human_size(sync_status.progress.total_size),
        :size           => sync_status.progress.total_size,
        :is_running     => !not_running_states.include?(sync_status.state.to_sym),
        :error_details  => error_details ? error_details : "No errors."
    }
  end

  def format_state(state)
    @@status_values[state.to_sym]
  end

  def format_duration(finish, start)
    retval = nil
    if !finish.nil? && !start.nil?
      retval = distance_of_time_in_words(finish, start)
    end
    retval
  end

  def format_date(check_date)
    retval = nil
    if !check_date.nil?
      retval = relative_time_in_words(check_date)
    end
    retval
  end

  # loop through checkbox list of products and sync
  def sync_repos(repos)
    repos = [repos] if !repos.is_a? Array
    collected = []
    repos = Repository.where(:id => repos).syncable
    repos.each do |repo|
      begin
        resp = repo.sync(:notify => true).first
        collected.push(:id => repo.id, :product_id => repo.product.id, :state => resp[:state])
      rescue RestClient::Conflict
        notify.error N_("There is already an active sync process for the '%s' repository. Please try again later") %
                        repo.name
      end
    end
    collected
  end

  # calculate the % complete of ongoing sync from pulp
  def calc_progress(val, content_type)

    if content_type == Repository::PUPPET_TYPE
      completed = val.progress.total_count - val.progress.items_left
      progress = if val.state =~ /error/i then -1
                 elsif val.progress.total_count == 0 then 0
                 else completed.to_f / val.progress.total_count.to_f * 100
                 end
    else
      completed = val.progress.total_size - val.progress.size_left
      progress = if val.state =~ /error/i then -1
                 elsif val.progress.total_size == 0 then 0
                 else completed.to_f / val.progress.total_size.to_f * 100
                 end
    end

    {:count => val.progress.total_count,
     :left => val.progress.items_left,
     :progress => progress
    }
  end

  def get_product_info(product)
    product_size = 0
    product.repos(product.organization.library).each do |repo|
      status = repo.sync_status
      @repo_status[repo.id] = format_sync_progress(status, repo)
      product_size += status.progress.total_size
    end
    @product_size[product.id] = number_to_human_size(product_size)
  end
end
end
