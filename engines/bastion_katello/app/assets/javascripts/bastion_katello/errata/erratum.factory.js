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

/**
 * @ngdoc service
 * @name  Bastion.errata.factory:Erratum
 *
 * @requires BastionResource
 *
 * @description
 *   Provides a BastionResource for Errata
 */
angular.module('Bastion.errata').factory('Erratum',
    ['BastionResource', function (BastionResource) {

        return BastionResource('/api/v2/errata/:id/', {id: '@id'}, {
            applicableContentHosts: {method: 'GET', transformResponse: function (data) {
                var erratum = angular.fromJson(data),
                    systems = erratum['systems_applicable'];
                return {results: systems, subtotal: systems.length, total: systems.length};
            }}
        });

    }]
);
