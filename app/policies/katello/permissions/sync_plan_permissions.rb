require 'katello/plugin.rb'

Foreman::Plugin.find(:katello).security_block :sync_plans do
  permission :view_sync_plans,
             {
                 'katello/sync_plans' => [:all, :index],
                 'katello/api/v2/sync_plans' => [:index, :show, :available_products]
             },
             :resource_type => 'Katello::SyncPlan'
  permission :create_sync_plans,
             {
                 'katello/api/v2/sync_plans' => [:create],
             },
             :resource_type => 'Katello::SyncPlan'
  permission :update_sync_plans,
             {
                 'katello/api/v2/sync_plans' => [:update, :add_products, :remove_products],
             },
             :resource_type => 'Katello::SyncPlan'
  permission :destroy_sync_plans,
             {
                 'katello/api/v2/sync_plans' => [:destroy],
             },
             :resource_type => 'Katello::SyncPlan'
end
