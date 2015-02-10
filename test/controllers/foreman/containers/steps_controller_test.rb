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

require 'katello_test_helper'

module Containers
  class StepsControllerTest < ActionController::TestCase
    def setup
      setup_controller_defaults(false, false)
      login_user(User.find(users(:admin)))
      @compute_resource = FactoryGirl.create(:docker_stuff)
      @state = DockerContainerWizardState.create!
      @state.preliminary = DockerContainerWizardStates::Preliminary.create!(:wizard_state => @state,
                                                                            :compute_resource_id => @compute_resource.id)
      DockerContainerWizardState.expects(:find).at_least_once.returns(@state)
    end

    def test_show_image_loads_katello
      get :show, :wizard_state_id => @state.id,
                 :id => :image
      assert @state.image.katello?
      assert response.body.include?("katello/containers/container.js") # this is code generated by katello partial
      docker_image = @controller.instance_eval do
        @docker_container_wizard_states_image
      end
      assert_equal @state.image, docker_image
    end

    def test_create_image_with_katello
      repo = OpenStruct.new(:id => 100, :pulp_id => "repo_pulp_id")
      ::Katello::Repository.expects(:where).with(:id => repo.id.to_s).returns([repo])

      tag = OpenStruct.new(:id => 200, :name => "tag_name")
      ::Katello::DockerTag.expects(:where).with(:id => tag.id.to_s).returns([tag])

      capsule_id = 300
      image  = OpenStruct.new(:id => 1000)

      @state.expects(:build_image).with(:repository_name => repo.pulp_id,
                                        :tag => tag.name,
                                        :capsule_id => capsule_id.to_s,
                                        :katello => true).returns(image)

      put :update, :wizard_state_id => @state.id,
                   :id => :image,
                   :katello => true,
                   :repository => {:id => repo.id},
                   :tag => {:id => tag.id},
                   :capsule => {:id => capsule_id}

      docker_image = @controller.instance_eval do
        @docker_container_wizard_states_image
      end
      assert_equal image, docker_image
    end
  end
end
