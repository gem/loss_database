#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim: tabstop = 4 shiftwidth = 4 softtabstop = 4
#
# Copyright (c) 2018, GEM Foundation.
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


class LossModel():
    """
    Representation of a loss model - a collection of loss maps and/or
    loss curve maps

    :param name:
    :param description:
    """
    def __init__(self, name, description=None):
        self.name = name
        self.description = description
        self.id = None


class Contribution():
    """
    Meta-Data description a contribution: date, source, etc.

    :param model_id:
    :param model_source:
    :param model_date:
    :param license_id:
    :param notes:
    :param version:
    :param purpose:
    """
    def __init__(self, model_id, model_source, model_date, license_id,
                 notes=None, version=None, purpose=None):
        self.model_id = model_id
        self.model_source = model_source
        self.model_date = model_date
        self.license_id = license_id
        self.notes = notes
        self.version = version
        self.purpose = purpose


class LossMap():
    """
    Map of loss values (but not curves)
    """
    def __init__(self, model_id, occupancy, loss_type
                 return_period=None, units, metric):
        self.model_id = model_id
        self.occupancy = occupancy
        self.loss_type = loss_type
        self.return_period = return_period
        self.units = units
        self.metric = metric
        id = None
        self.values = []


class LossMapValue():
    """
    Individual loss value for a given location
    """
    def __init__(self, loss_map_id, asset_ref=None,
                 geometry, loss):
        self.loss_model_id = loss_map_id
        self.asset_ref = asset_ref
        self.geometry = geometry
        self.loss = loss


class LossCurveMap():
    """
    Map of loss curves
    """
    def __init__(self, model_id, occupancy, component, loss_type
                 frequency, return_period=None,
                 investigation_time=None, units):
        self.model_id = model_id
        self.occupancy = occupancy
        self.component = component
        self.loss_type = loss_type
        self.frequency = frequency
        self.return_period = return_period
        self.investigation_time = investigation_time
        self.units = units
        id = None
        self.curves = []


class LossCurveMapValues():
    """
    Individual loss curve for a given location
    """
    def __init__(self, loss_curve_map_id, asset_ref=None,
                 geometry, losses, rates):
        self.loss_model_id = loss_map_id
        self.asset_ref = asset_ref
        self.geometry = geometry
        self.losses = losses
        self.rates = rates
