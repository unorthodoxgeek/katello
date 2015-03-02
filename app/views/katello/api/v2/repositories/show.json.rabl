object @resource

extends 'katello/api/v2/common/identifier'
extends 'katello/api/v2/common/org_reference'
extends 'katello/api/v2/common/timestamps'

attributes :content_type
attributes :docker_upstream_name
attributes :unprotected, :full_path, :checksum_type
attributes :url,
           :relative_path
attributes :major, :minor
attributes :gpg_key_id
attributes :content_id, :content_view_version_id, :library_instance_id
attributes :product_type
attributes :promoted? => :promoted

child :content_counts do |repo|
  extends 'katello/api/v2/repositories/_content_counts'
end

node :permissions do |repo|
  {
    :deletable => repo.deletable?
  }
end

child :gpg_key do |_gpg|
  attribute :name
  attribute :id
end

child :product do |product|
  attribute :id
  attribute :cp_id
  attribute :name
  node :sync_plan do |_sync_plan|
    partial('katello/api/v2/sync_plans/show', :object => product.sync_plan)
  end
end

if @object && @object.library_instance_id.nil?

  node :content_view_environments do |repository|
    Katello::RepositoryPresenter.new(repository).content_view_environments
  end

end

child :environment => :environment do |_repo|
  attribute :id
end

child :latest_dynflow_sync => :last_sync do |_object|
  attributes :id, :username, :started_at, :ended_at, :state, :result, :progress
end

node :last_sync_words do |object|
  if (object.latest_dynflow_sync.respond_to?('ended_at') && object.latest_dynflow_sync.ended_at)
    time_ago_in_words(Time.parse(object.latest_dynflow_sync.ended_at.to_s))
  end
end
