/**
 * Copyright 2014 Red Hat, Inc.
 *
 * This software is licensed to you under the GNU General Public
 * License as published by the Free Software Foundation; either version
 * 2 of the License (GPLv2) or (at your option) any later version.
 * There is NO WARRANTY for this software, express or implied,
 * including the implied warranties of MERCHANTABILITY,
 * NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
 * have received a copy of GPLv2 along with this software; if not, see
 * http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
*/

/**
 * @ngdoc object
 * @name  Bastion.errata.controller:ErrataController
 *
 * @requires $scope
 * @requires $location
 * @requires translate
 * @requires Nutupane
 * @requires Erratum
 * @requires Repository
 * @requires CurrentOrganization
 *
 * @description
 *   Provides the functionality specific to errata for use with the Nutupane UI pattern.
 *   Defines the columns to display and the transform function for how to generate each row
 *   within the table.
 */
angular.module('Bastion.errata').controller('ErrataController',
    ['$scope', '$location', 'translate', 'Nutupane', 'Erratum', 'Task', 'Repository', 'CurrentOrganization',
    function ($scope, $location, translate, Nutupane, Erratum, Task, Repository, CurrentOrganization) {
        var nutupane, params = {
            'organization_id':  CurrentOrganization,
            'search':           $location.search().search || "",
            'sort_by':          'updated',
            'sort_order':       'DESC',
            'paged':            true,
            'errata_restrict_applicable': true
        };

        nutupane = $scope.nutupane = new Nutupane(Erratum, params);
        $scope.table = nutupane.table;
        $scope.removeRow = nutupane.removeRow;

        $scope.table.closeItem = function () {
            $scope.transitionTo('errata.index');
        };

        $scope.repository = {name: translate('All Repositories'), id: 'all'};

        $scope.checkIfIncrementalUpdateRunning = function () {
            var searchId, taskSearchParams, taskSearchComplete;

            taskSearchParams = {
                'type': 'all',
                "resource_type": "Organization",
                "resource_id": CurrentOrganization,
                "action_types": "Actions::Katello::ContentView::IncrementalUpdates",
                "active_only" : true
            };

            taskSearchComplete = function (results) {
                console.log(results);
                $scope.incrementalUpdateInProgress = results.length > 0;
                Task.unregisterSearch(searchId);
            };

            searchId = Task.registerSearch(taskSearchParams, taskSearchComplete);
        };

        Repository.queryUnpaged({'organization_id': CurrentOrganization, 'content_type': 'yum'}, function (response) {
            $scope.repositories = [$scope.repository];
            $scope.repositories = $scope.repositories.concat(response.results);

            if ($location.search().repositoryId) {
                $scope.repository = _.find($scope.repositories, function (repository) {
                    return repository.id === parseInt($location.search().repositoryId, 10);
                });
            }
        });

        $scope.showApplicable = true;
        $scope.showInstallable = false;

        $scope.toggleApplicable = function () {
            nutupane.table.params['errata_restrict_applicable'] = $scope.showApplicable;
            nutupane.refresh();
        };

        $scope.toggleInstallable = function () {
            nutupane.table.params['errata_restrict_installable'] = $scope.showInstallable;
            nutupane.refresh();
        };

        $scope.$watch('repository', function (repository) {
            var params = nutupane.getParams();

            if (repository.id === 'all') {
                params['repository_id'] = null;
                nutupane.setParams(params);
            } else {
                $location.search('repositoryId', repository.id);
                params['repository_id'] = repository.id;
                nutupane.setParams(params);
            }

            nutupane.refresh();
        });

        $scope.goToNextStep = function () {
            $scope.selectedErrata = nutupane.getAllSelectedResults();
            $scope.transitionTo('errata.apply.select-content-hosts');
        };

        $scope.checkIfIncrementalUpdateRunning();
    }]
);
