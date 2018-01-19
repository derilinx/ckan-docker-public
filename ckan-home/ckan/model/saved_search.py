# encoding: utf-8

import datetime

from sqlalchemy import (
    orm,
    types,
    Column,
    Table,
    ForeignKey,
    desc,
    or_,
    and_,
    union_all
)

from sqlalchemy.dialects.postgresql import ARRAY, TEXT

import ckan.model
import meta
import types as _types
import domain_object

__all__ = ['SavedSearch', 'saved_search_table']

class SavedSearch(domain_object.DomainObject):

    def __init__(self, user_id, search_string, id = None, last_results = [], last_run = None):
        if id is None:
            self.id = _types.make_uuid()
        self.timestamp = datetime.datetime.utcnow()
        self.user_id = user_id
        self.last_run = last_run
        self.search_string = search_string
        self.last_results = last_results

saved_search_table = Table(
    'saved_search', meta.metadata,
    Column('id', types.UnicodeText, primary_key=True, default=_types.make_uuid),
    Column('timestamp', types.DateTime),
    Column('user_id', types.UnicodeText),
    Column('last_run', types.DateTime),
    Column('search_string', types.UnicodeText),
    Column('last_results', ARRAY(TEXT))
    )

meta.mapper(SavedSearch, saved_search_table)


def user_saved_searches_list(user_id):
    '''Return an SQLAlchemy query for all saved searches from user_id.'''
    import ckan.model as model
    q = model.Session.query(model.SavedSearch)
    q = q.filter(model.SavedSearch.user_id == user_id)

    return q
