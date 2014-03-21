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
describe Api::V1::PackagesController do
  describe "(katello)" do
  include OrganizationHelperMethods
  include AuthorizationHelperMethods
  include ProductHelperMethods
  include RepositoryHelperMethods
  include LocaleHelperMethods

  let(:repo_id) { 'f8ab5088-688e-4ce4-ade3-700aa4cbb070' }

  before(:each) do
    disable_org_orchestration
    disable_product_orchestration
    disable_user_orchestration
    disable_repo_orchestration
    setup_controller_defaults_api
    @organization = new_test_org
    @env          = @organization.library
    @product      = new_test_product(@organization, @env)
    @repo         = new_test_repo(@env, @product, "repo", "#{@organization.name}/Library/prod/repo")

    @product.stubs(:repos).returns([@repository])
    @repo.stubs(:has_distribution?).returns(true)
    @repo.stubs(:pulp_id).returns(repo_id)
    Repository.stubs(:find).returns(@repo)

    @repo.stubs(:packages).returns([])
    @package = { 'repository_memberships' => [repo_id] }.with_indifferent_access
    @request.env["HTTP_ACCEPT"] = "application/json"

    Katello.pulp_server.extensions.rpm.stubs(:find_by_unit_id).returns(@package)

  end

  describe "rules" do
    before do
      Package.stubs(:find).returns(Package.new(@package))
    end

    let(:authorized_user) do
      user_with_permissions do |u|
        u.can(:read_contents, :environments, @organization.library.id, @organization)
        u.can(:read, :providers, @provider.id, @organization)
      end
    end
    let(:unauthorized_user) do
      user_without_permissions
    end
    describe "get a listing by repo" do
      let(:action) { :index }
      let(:req) {
        get 'index', :repository_id => repo_id
      }
      it_should_behave_like "protected action"
    end

    describe "show" do
      let(:action) { :show }
      let(:req) {
        get 'show', :id => 1, :repository_id => repo_id
      }
      it_should_behave_like "protected action"
    end

    describe "search" do
      let(:action) { :search }
      let(:req) {
        get 'search', :id => 1, :repository_id => repo_id, :query => "cheetah*"
      }
      it_should_behave_like "protected action"
    end
  end

  context "tests" do
    before do
      disable_authorization_rules
    end
    describe "get a listing of packages" do
      it "should call pulp find packages api" do
        Repository.expects(:find).with(repo_id)
        get 'index', :repository_id => repo_id
      end
    end

    describe "show a package" do
      it "should call pulp find package api" do
        Katello.pulp_server.extensions.rpm.expects(:find_by_unit_id).once.with('1')
        get 'show', :id => '1', :repository_id => repo_id
      end
    end

    describe "search for a package" do
      it "should call glue layer" do
        Katello::Package.expects(:search).once.with("cheetah*", 0, 0, [@repo.pulp_id])
        get 'search', :repository_id => repo_id, :search => "cheetah*"
      end
    end
  end
end
end
end