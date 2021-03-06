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

module Katello
describe Api::V1::OrganizationsController do
  include AuthorizationHelperMethods
  include OrganizationHelperMethods

  let(:user_with_index_permissions) { user_with_permissions { |u| u.can([:read], :organizations) } }
  let(:user_without_index_permissions) { user_without_permissions }
  let(:user_with_read_permissions) { user_with_permissions { |u| u.can(Organization::READ_PERM_VERBS, :organizations) } }
  let(:user_without_read_permissions) { user_without_permissions }
  let(:user_with_create_permissions) { user_with_permissions { |u| u.can([:create], :organizations) } }
  let(:user_without_create_permissions) { user_with_permissions { |u| u.can([:update], :organizations) } }
  let(:user_with_update_permissions) { user_with_permissions { |u| u.can([:create], :organizations) } }
  let(:user_without_update_permissions) { user_without_permissions }
  let(:user_with_destroy_permissions) { user_with_permissions { |u| u.can([:delete], :organizations) } }
  let(:user_without_destroy_permissions) { user_with_permissions { |u| u.can([:update], :organizations) } }

  before(:each) do
    @org = new_test_org
    @controller.stubs(:get_organization => @org)
    @request.env["HTTP_ACCEPT"] = "application/json"
    setup_controller_defaults_api
  end

  describe "create" do

    let(:action) { :create }
    let(:authorized_user) { user_with_create_permissions }
    let(:unauthorized_user) { user_without_create_permissions }

    describe "root org" do

      let(:req) { post 'create', :name => 'test org', :description => 'description' }
      it_should_behave_like "protected action"

      it 'should call katello create organization api' do
        Organization.expects(:create!).once.with(:name => 'test org', :description => 'description', :label => 'test_org').returns(@org)
        req
      end
    end

    describe "with missing label from POST and name converted to label" do

      let(:req) { post 'create', :name => 'test org with spaces', :description => 'description' }
      it_should_behave_like "protected action"

      it 'should call katello create organization api' do
        Organization.expects(:create!).once.with(:name  => 'test org with spaces', :description => 'description',
                                                        :label => 'test_org_with_spaces').returns(@org)
        req
      end
    end

    describe "with label not equal to the name" do

      let(:req) { post 'create', :name => 'test org', :description => 'description', :label => "some_other_label" }
      it_should_behave_like "protected action"

      it 'should call katello create organization api' do
        Organization.expects(:create!).once.with(:name  => 'test org', :description => 'description',
                                                        :label => 'some_other_label').returns(@org)
        req
      end
    end
  end

  describe "listing" do

    let(:action) { :index }
    let(:req) { get 'index' }
    let(:authorized_user) { user_with_index_permissions }
    let(:unauthorized_user) { user_without_index_permissions }
    it_should_behave_like "protected action"

    it 'should find all readable orgs that are not being deleted' do
      Organization.expects(:without_deleting).at_least_once.returns(Organization)
      Organization.expects(:readable).at_least_once.returns(Organization)
      Organization.expects(:where).once
      req
    end
  end

  describe "show" do

    let(:action) { :show }
    let(:req) { get 'show', :id => "spec" }
    let(:authorized_user) { user_with_read_permissions }
    let(:unauthorized_user) { user_without_read_permissions }
    it_should_behave_like "protected action"

    it 'should call katello organization find api' do
      @controller.expects(:find_organization)
      req
    end
  end

  describe "delete" do

    let(:action) { :destroy }
    let(:req) { delete 'destroy', :id => "spec" }
    let(:authorized_user) { user_with_destroy_permissions }
    let(:unauthorized_user) { user_without_destroy_permissions }
    it_should_behave_like "protected action"

    it 'should find org' do
      @controller.expects(:find_organization)
      req
    end

    it 'should call organization destroyer' do
      OrganizationDestroyer.expects(:destroy).with(@org).once
      req
    end
  end

  describe "repo discovery" do
    let(:action) { :discovery }
    let(:req) { post :repo_discover, { :id => @org.name, :url => 'http://testurl.com/path/' } }
    let(:authorized_user) { user_with_update_permissions }
    let(:unauthorized_user) { user_without_update_permissions }
    it_should_behave_like "protected action"

    it "should call into Repo discovery" do
      @org.expects(:discover_repos).returns(TaskStatus.new)
      req
    end
  end

  describe "update" do

    let(:action) { :update }
    let(:req) { put 'update', :id => "spec", :organization => { :description => "bah" } }
    let(:authorized_user) { user_with_update_permissions }
    let(:unauthorized_user) { user_without_update_permissions }
    it_should_behave_like "protected action"

    it 'should find org' do
      @controller.expects(:find_organization)
      req
    end

    it 'should call org update_attributes' do
      @org.expects(:update_attributes!).once
      req
    end

    describe "invalid params" do
      let(:req) do
        bad_req = { :id           => 123,
                    :organization =>
                        { :bad_foo     => "mwahahaha",
                          :name        => "Gpg Key",
                          :description => "This is the key string" }
        }.with_indifferent_access
        put :update, bad_req
      end
      it_should_behave_like "bad request"

    end
  end
end
end