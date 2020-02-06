#
# -*- coding: utf-8 -*-
# vim: tabstop=4 shiftwidth=4 softtabstop=4
#
# Copyright (c) 2019, GEM Foundation.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.
# If not, see <https://www.gnu.org/licenses/agpl.html>.
#

import sys

class Contribution():
    """
    Meta-Data description a contribution: date, source, etc.

    :param model_id:
    :param model_source:
    :param model_date:
    :param license_code:
    :param notes:
    :param version:
    :param purpose:
    """
    def __init__(self, model_id, model_source, model_date, license_code,
                 notes=None, version=None, purpose=None, project=None,
                 contributed_at=None):
        self.model_id = model_id
        self.model_source = model_source
        self.model_date = model_date
        self.license_code = license_code
        self.notes = notes
        self.version = version
        self.purpose = purpose
        self.project = project
        self.contributed_at = contributed_at

    """
    Create a Contribution from a meta-data dictionary.  Maps license
    codes to IDs automatically
    """
    @classmethod
    def from_md(cls, md):
        return Contribution(
            None,
            md.get('model_source'),
            md.get('model_date'),
            md.get('license_code'),
            md.get('notes'),
            md.get('version'),
            md.get('purpose'),
            md.get('project'),
            md.get('contributed_at'))
