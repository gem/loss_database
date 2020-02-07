#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: tabstop=4 shiftwidth=4 softtabstop=4
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
"""
Support for importing a loss model into the Challenge Fund loss database
"""

import json
import sys

from loss_model import LossModel
from cf_common import Contribution
from database import db_connections
import db_settings

VERBOSE = True


def verbose_message(msg):
    """
    Display message if we are in verbose mode
    """
    if VERBOSE:
        sys.stderr.write(msg)


_LOSS_MODEL_QUERY = """
INSERT INTO loss.loss_model(
    name, description, hazard_type, process_type,
    hazard_link, exposure_link, vulnerability_link)
VALUES (%s, %s, %s, %s, %s, %s, %s)
RETURNING id
"""


def _import_loss_model(cursor, loss_model):
    cursor.execute(_LOSS_MODEL_QUERY, [
            loss_model.name,
            loss_model.description,
            loss_model.hazard_type,
            loss_model.process_type,
            loss_model.hazard_link,
            loss_model.exposure_link,
            loss_model.vulnerability_link
    ])
    return cursor.fetchone()[0]


_CONTRIBUTION_QUERY = """
INSERT INTO loss.contribution (
    loss_model_id, model_source, model_date,
    notes, license_code, version, purpose, project)
VALUES(
    %s, %s, %s,
    %s, %s, %s, %s, %s
)
"""


def _import_contribution(cursor, model_id, md):
    if(md is None):
        return
    contribution = Contribution.from_md(md)
    cursor.execute(_CONTRIBUTION_QUERY, [
        model_id,
        contribution.model_source,
        contribution.model_date,
        contribution.notes,
        contribution.license_code,
        contribution.version,
        contribution.purpose,
        contribution.project
    ])


_LOSS_MAP_QUERY = """
INSERT INTO loss.loss_map (
    loss_model_id, occupancy, component, loss_type,
    return_period, units, metric)
VALUES (
    %s, %s, %s, %s,
    %s, %s, %s
)
RETURNING id
"""


def _import_loss_map(cursor, loss_model_id, loss_map):
    cursor.execute(_LOSS_MAP_QUERY, [
        loss_model_id,
        loss_map.occupancy,
        loss_map.component,
        loss_map.loss_type,
        loss_map.return_period,
        loss_map.units,
        loss_map.metric
    ])
    return cursor.fetchone()[0]


_LOSS_MAP_VALUES_QUERY = """
INSERT INTO loss.loss_map_values (
    loss_map_id, asset_ref, the_geom, loss)
VALUES (
    %s, %s, ST_GeomFromText(%s,4326), %s
)
"""


def _import_loss_map_values(cursor, loss_map_id, lm_values):
    verbose_message("Importing {0} values for loss_map {1}\n".format(
        len(lm_values), loss_map_id))
    for lmv in lm_values:
        cursor.execute(_LOSS_MAP_VALUES_QUERY, [
            loss_map_id,
            lmv.asset_ref,
            lmv.geometry,
            lmv.loss
        ])


_LOSS_MAP_VALUES_QUERY_TEMPLATE = """
INSERT INTO loss.loss_map_values (
    loss_map_id, asset_ref, the_geom, loss)
    (SELECT %s AS loss_map_id, %s)
"""


def _import_loss_map_values_via_query(cursor, loss_map_id, query):
    bulk_query = _LOSS_MAP_VALUES_QUERY_TEMPLATE % (loss_map_id, query)
    verbose_message("Bulk loss map query = {0}".format(bulk_query))
    cursor.execute(bulk_query)


def _import_loss_maps(cursor, loss_model_id, loss_maps):
    for lm in loss_maps:
        lmid = _import_loss_map(cursor, loss_model_id, lm)
        d = lm.directives
        if d is not None:
            q = d.get('_cf_loss_map_value_data_query')
            if q is not None:
                verbose_message("Import LM found query {0}".format(q))
                _import_loss_map_values_via_query(cursor, lmid, q)
                return
        _import_loss_map_values(cursor, lmid, lm.values)


_LOSS_CURVE_MAP_QUERY = """
INSERT INTO loss.loss_curve_map (
    loss_model_id, occupancy, component, loss_type,
    frequency, investigation_time, units)
VALUES (
    %s, %s, %s, %s,
    %s, %s, %s
)
RETURNING id
"""


def _import_loss_curve_map(cursor, loss_model_id, loss_curve_map):
    cursor.execute(_LOSS_CURVE_MAP_QUERY, [
        loss_model_id,
        loss_curve_map.occupancy,
        loss_curve_map.component,
        loss_curve_map.loss_type,
        loss_curve_map.frequency,
        loss_curve_map.investigation_time,
        loss_curve_map.units
    ])
    return cursor.fetchone()[0]


_LOSS_CURVE_MAP_VALUES_QUERY_TEMPLATE = """
INSERT INTO loss.loss_curve_map_values (
    loss_curve_map_id, asset_ref, the_geom, losses, rates)
    (SELECT %s AS loss_curve_map_id, %s)
"""


def _import_loss_curve_map_values_via_query(cursor, lmcmid, query):
    bulk_query = _LOSS_CURVE_MAP_VALUES_QUERY_TEMPLATE % (
        lmcmid, query)
    verbose_message("Bulk loss curve map query = {0}".format(bulk_query))
    cursor.execute(bulk_query)


_LOSS_CURVE_MAP_VALUES_QUERY = """
INSERT INTO loss.loss_curve_map_values (
    loss_curve_map_id, asset_ref, the_geom, losses, rates)
VALUES (
    %s, %s, ST_GeomFromText(%s,4326), %s, %s
)
"""


def _import_loss_curve_map_values(cursor, loss_map_id, lcm_values):
    for lcmv in lcm_values:
        cursor.execute(_LOSS_CURVE_MAP_VALUES_QUERY, [
            loss_map_id,
            lcmv.asset_ref,
            lcmv.geometry,
            lcmv.losses,
            lcmv.rates
        ])


def _import_loss_curve_maps(cursor, loss_model_id, loss_curve_maps):
    for lcm in loss_curve_maps:
        lcmid = _import_loss_curve_map(cursor, loss_model_id, lcm)
        d = lcm.directives
        if d is not None:
            q = d.get('_cf_loss_curve_map_value_data_query')
            if q is not None:
                _import_loss_curve_map_values_via_query(cursor, lcmid, q)
                return
        _import_loss_curve_map_values(cursor, lcmid, lcm.values)


def import_loss_model(loss_model):
    """
    Import loss_model into the loss DB, return id
    """
    verbose_message("Model contains {0} maps\n" .format(
        len(loss_model.loss_maps)))
    verbose_message("Model contains {0} curve maps\n" .format(
        len(loss_model.loss_curve_maps)))
    connections = db_connections(db_settings.db_confs)
    connection = connections['loss_contrib']

    with connection.cursor() as cursor:
        model_id = _import_loss_model(cursor, loss_model)
        _import_contribution(
            cursor, model_id, loss_model.contribution)
        _import_loss_maps(cursor, model_id, loss_model.loss_maps)
        _import_loss_curve_maps(
            cursor, model_id, loss_model.loss_curve_maps)
        connection.commit()
        verbose_message('Inserted loss model, id={0}\n'.format(model_id))
        return model_id


def dumper(obj):
    try:
        return obj.as_dict()
    except AttributeError:
        return obj.__dict__


def main():
    if len(sys.argv) != 2:
        sys.stderr.write('Usage {0} meta-data\n'.format(
            sys.argv[0]))
        exit(1)

    md_file = sys.argv[1]

    verbose_message("Reading meta-data file {0}\n".format(
        md_file))

    md = {}
    with open(md_file, 'r') as fin:
        md = json.load(fin)

    loss_model = LossModel.from_md(md)

    with open('md_out.json', 'w') as fout:
        json.dump(loss_model, fout, default=dumper, indent=2)

    imported_id = import_loss_model(loss_model)
    sys.stderr.write("Imported model id = {0}\n".format(imported_id))


if __name__ == "__main__":
    main()
