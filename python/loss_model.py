#
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
        self.contribution = None
        self.loss_maps = []
        self.loss_curve_maps = []

    """
    Create a LossModel from a meta-data dictionary
    """
    @classmethod
    def from_md(cls, md):
        model = LossModel(md.get('name'), md.get('description'))
        model.contribution = md.get('contribution')
        loss_maps = md.get('loss_maps')
        if(loss_maps is not None):
            for lm in loss_maps:
                model.loss_maps.append(LossMap.from_md(lm))
        loss_curve_maps = md.get('loss_curve_maps')
        if(loss_curve_maps is not None):
            for lcm in loss_curve_maps:
                model.loss_curve_maps.append(LossCurveMap.from_md(lcm))
        return model


class LossMap():
    """
    Map of loss values (but not curves)
    """
    def __init__(self, model_id, occupancy, component, loss_type,
                 units, metric,
                 return_period=None, directives=None):
        self.model_id = model_id
        self.occupancy = occupancy
        self.component = component
        self.loss_type = loss_type
        self.return_period = return_period
        self.units = units
        self.metric = metric
        self.directives = directives
        self.values = []

    @classmethod
    def from_md(cls, md):
        loss_map = LossMap(
            None,
            md.get('occupancy'),
            md.get('component'),
            md.get('loss_type'),
            md.get('units'),
            md.get('metric'),
            md.get('return_period'),
            md)
        return loss_map


class LossMapValue():
    """
    Individual loss value for a given location
    """
    def __init__(self, loss_map_id, geometry, loss, asset_ref=None,):
        self.loss_model_id = loss_map_id
        self.asset_ref = asset_ref
        self.geometry = geometry
        self.loss = loss


class LossCurveMap():
    """
    Map of loss curves
    """
    def __init__(self, model_id, occupancy, component, loss_type,
                 frequency, units,
                 return_period=None, investigation_time=None,
                 directives=None):
        self.model_id = model_id
        self.occupancy = occupancy
        self.component = component
        self.loss_type = loss_type
        self.frequency = frequency
        self.return_period = return_period
        self.investigation_time = investigation_time
        self.units = units
        self.directives = directives
        self.values = []

    @classmethod
    def from_md(cls, md):
        loss_map = LossCurveMap(
            None,
            md.get('occupancy'),
            md.get('component'),
            md.get('loss_type'),
            md.get('frequency'),
            md.get('units'),
            md.get('return_period'),
            md.get('investigation_time'),
            md)
        return loss_map


class LossCurveMapValues():
    """
    Individual loss curve for a given location
    """
    def __init__(self, loss_curve_map_id,
                 geometry, losses, rates, asset_ref=None):
        self.loss_curve_map_id = loss_curve_map_id
        self.asset_ref = asset_ref
        self.geometry = geometry
        self.losses = losses
        self.rates = rates
