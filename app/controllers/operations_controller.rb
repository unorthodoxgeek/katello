#
# Copyright 2011 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

class OperationsController < ApplicationController

  def rules
    {
      :index => lambda{user.allowed_to?(*[[:read, :update, :create, :delete], :users]) or
          user.allowed_to?(*[[:read, :update, :create, :delete], :roles])}
    }.with_indifferent_access
  end



  def index
  end
  def section_id
    'operations'
  end
end
