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
 **/

describe('Controller: ErrataContentHostsController', function() {
    var $scope, translate, Nutupane, ContentHost, ContentHostBulkAction,
        CurrentOrganization;

    beforeEach(module('Bastion.errata', 'Bastion.test-mocks'));

    beforeEach(inject(function($injector) {
        var $controller = $injector.get('$controller');

        translate = function (string) {
            return string;
        };

        Nutupane = function() {
            this.table = {
                params: {},
                showColumns: function () {}
            };
            this.enableSelectAllResults = function () {};
            this.getAllSelectedResults = function () {
                return {include: [1, 2, 3]};
            };
            this.refresh = function () {};
            this.load = function () {
                return {then: function () {}}
            };
        };

        ContentHost = {};

        ContentHostBulkAction = {
            failed: false,
            installContent: function (params, success, error) {
                if (this.failed) {
                    error({errors: ['error']});
                } else {
                    success();
                }
            }
        };


        CurrentOrganization = 'foo';
        
        $scope = $injector.get('$rootScope').$new();
        $scope.$stateParams = {errataId: 1};

        $controller('ErrataContentHostsController', {
            $scope: $scope,
            translate: translate,
            Nutupane: Nutupane,
            ContentHost: ContentHost,
            ContentHostBulkAction: ContentHostBulkAction,
            CurrentOrganization: CurrentOrganization                      
        });
    }));

    it("puts the errata content hosts table object on the scope", function() {
        expect($scope.detailsTable).toBeDefined();
    });

    it("allows the filtering of available errata only", function () {
        $scope.errata = {
            showAvailable: true
        };
        
        $scope.toggleAvailable();
        expect($scope.detailsTable.params['erratum_restrict_available']).toBe(true)
    });

    describe("can apply errata", function () {
        var expectedParams;

        beforeEach(function () {
            $scope.errata = {'errata_id': 10},
            expectedParams = {
                include: [1, 2, 3],
                'content_type': 'errata',
                content: [$scope.errata['errata_id']],
                'organization_id': CurrentOrganization

            };
            spyOn(ContentHostBulkAction, 'installContent').andCallThrough();
        });

        afterEach(function () {
            expect(ContentHostBulkAction.installContent).toHaveBeenCalledWith(expectedParams, jasmine.any(Function),
                jasmine.any(Function));
        });

        it("and succeed", function () {
            $scope.applyErrata();

            expect($scope.successMessages.length).toBe(1);
            expect($scope.errorMessages.length).toBe(0);
        });

        it("and fail", function () {
            ContentHostBulkAction.failed = true;
            $scope.applyErrata();

            expect($scope.successMessages.length).toBe(0);
            expect($scope.errorMessages.length).toBe(1);
            expect($scope.errorMessages[0]).toBe('error');
        });
    });
});
