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
Support for exporting a loss model from the Challenge Fund loss database
"""

import json
import sys
import datetime

from loss_model import LossModel, LossMap, LossMapValue, \
    LossCurveMap, LossCurveMapValue
from cf_common import Contribution, License

from django.db import connections
from django.conf import settings

import db_settings
settings.configure(DATABASES=db_settings.DATABASES)


VERBOSE = True


def verbose_message(msg):
    """
    Display message if we are in verbose mode
    """
    if VERBOSE:
        sys.stderr.write(msg)


def dictfetchall(cursor):
    "Return all rows from a cursor as a dict"
    columns = [col[0] for col in cursor.description]
    return [
        dict(zip(columns, row))
        for row in cursor.fetchall()
    ]


def dictfetchone(cursor):
    "Return first row from a cursor as a dict"
    row = cursor.fetchone()
    if row is None or len(row) == 0:
        return None
    else:
        columns = [col[0] for col in cursor.description]
        return dict(zip(columns, row))


_LIST_LOSS_MODELS_QUERY = """
SELECT * FROM loss.loss_model ORDER BY id
"""


def _list_loss_models(cursor):
    cursor.execute(_LIST_LOSS_MODELS_QUERY)
    return dictfetchall(cursor)


_LOSS_MODEL_QUERY = """
SELECT * FROM loss.loss_model where id=%s
"""


def load_loss_model(cursor, loss_model_id):
    "Load the LossModel with the given id from the DB"
    cursor.execute(_LOSS_MODEL_QUERY, [
            loss_model_id
    ])
    md = dictfetchone(cursor)
    if md is None:
        return None
    lm = LossModel.from_md(md)
    lm.contribution = _load_contribution(cursor, loss_model_id)
    lm.loss_maps = _load_loss_maps(cursor, loss_model_id)
    lm.loss_curve_maps = _load_loss_curve_maps(cursor, loss_model_id)
    return lm


_CONTRIBUTION_QUERY = """
SELECT * FROM loss.contribution WHERE loss_model_id=%s
"""


def _load_contribution(cursor, model_id):
    cursor.execute(_CONTRIBUTION_QUERY, [
        model_id
    ])
    return Contribution.from_md(dictfetchone(cursor))


_LOSS_MAP_QUERY = """
SELECT * FROM loss.loss_map WHERE loss_model_id=%s ORDER BY id
"""


def _load_loss_maps(cursor, loss_model_id):
    cursor.execute(_LOSS_MAP_QUERY, [
        loss_model_id
    ])
    columns = [col[0] for col in cursor.description]
    maps = [
        LossMap.from_md(dict(zip(columns, row)))
        for row in cursor.fetchall()
    ]
    for lm in maps:
        lmid = lm.directives.get('id')
        lm.values = _load_loss_map_values(cursor, lmid, lm)
    return maps


_LOSS_MAP_VALUES_QUERY = """
SELECT loss, asset_ref, ST_AsText(ST_Normalize(the_geom)) AS geometry
FROM loss.loss_map_values WHERE loss_map_id=%s 
ORDER BY id
"""


def _load_loss_map_values(cursor, loss_map_id, lm):
    cursor.execute(_LOSS_MAP_VALUES_QUERY, [
        loss_map_id
    ])
    columns = [col[0] for col in cursor.description]
    return [
        LossMapValue.from_md(dict(zip(columns, row)))
        for row in cursor.fetchall()
    ]


_LOSS_CURVE_MAP_QUERY = """
SELECT * FROM loss.loss_curve_map WHERE loss_model_id=%s ORDER BY id
"""


def _load_loss_curve_maps(cursor, loss_model_id):
    cursor.execute(_LOSS_CURVE_MAP_QUERY, [
        loss_model_id
    ])
    columns = [col[0] for col in cursor.description]
    maps = [
        LossCurveMap.from_md(dict(zip(columns, row)))
        for row in cursor.fetchall()
    ]
    for lcm in maps:
        lcmid = lcm.directives.get('id')
        lcm.values = _load_loss_curve_map_values(cursor, lcmid, lcm)
    return maps


_LOSS_CURVE_MAP_VALUES_QUERY = """
SELECT losses, rates, asset_ref, ST_AsText(the_geom) AS geometry
FROM loss.loss_curve_map_values WHERE loss_curve_map_id=%s
ORDER BY id
"""


def _load_loss_curve_map_values(cursor, loss_map_id, lcm):
    cursor.execute(_LOSS_CURVE_MAP_VALUES_QUERY, [
        loss_map_id
    ])
    columns = [col[0] for col in cursor.description]
    return [
        LossCurveMapValue.from_md(dict(zip(columns, row)))
        for row in cursor.fetchall()
    ]


def _show_loss_models():
    "Display a list of available loss models and ids on stdout"
    with connections['loss_contrib'].cursor() as cursor:
        License.load_licenses(cursor)
        models = _list_loss_models(cursor)
        for md in models:
            print('{0}\t{1}'.format(md.get('id'), md.get('name')))


def _export_loss_model(model_id):
    "Export the fiven model_id to a json file"
    verbose_message("Loading model {0}\n".format(
        model_id))

    loss_model = None
    with connections['loss_contrib'].cursor() as cursor:
        License.load_licenses(cursor)
        loss_model = load_loss_model(cursor, model_id)

    if loss_model is None:
        sys.stderr.write("Model {0} not found\n".format(model_id))
        exit(1)
    else:
        jname = 'loss_model_{0}.json'.format(model_id)
        with open(jname, 'w') as fout:
            json.dump(loss_model, fout, default=dumper, indent=2)
        verbose_message("Exported model id {0} to {1}\n".format(
            model_id, jname))


def dumper(obj):
    try:
        if isinstance(obj, datetime.date):
            # Ensure that dates are returned as strings, not dictionaries
            return str(obj)
        return obj.as_dict()
    except AttributeError:
        return obj.__dict__


def main():
    if len(sys.argv) == 1:
        _show_loss_models()
        exit(0)

    if(len(sys.argv) == 2):
        exit(_export_loss_model(sys.argv[1]))
    else:
        sys.stderr.write('Usage: {0} [<loss id>]\n'.format(
            sys.argv[0]))
        exit(1)


if __name__ == "__main__":
    main()
