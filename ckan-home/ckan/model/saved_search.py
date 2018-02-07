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

    def __init__(self, user_id, search_string):
        self.id = _types.make_uuid()
        self.timestamp = datetime.datetime.utcnow()
        self.user_id = user_id
        self.last_run = None
        self.search_string = search_string
        self.last_results = []

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

def _make_parameters(query_string):
    parts = query_string.split("&")
    res = {}
    for part in parts:
        s = part.split("=")
        if len(s) > 1:
            res[s[0]] = s[1]
    return res

def user_saved_searches_list(user_id):
    '''Return an SQLAlchemy query for all saved searches from user_id.'''
    import ckan.model as model
    q = model.Session.query(model.SavedSearch)
    q = q.filter(model.SavedSearch.user_id == user_id)

    return q

def saved_search_is_duplicate(user_id, search_string):
    '''Test whether an equivalent search already exists'''
    saved_searches = user_saved_searches_list(user_id)
    
    # We've already been careful to put all relevant info about the base url into
    # saved parameters for the call that saves the search, so we can safely only
    # compare the arguments (and not whether we searching org/grop etc. according
    # to base URL
    n_s_search = _make_parameters(search_string)
    
    for d_s_search in saved_searches:
        #ts += "\n" + str(n_s_search) + " : " + str(d_s_search
        if _make_parameters(d_s_search.search_string) == n_s_search:
            return True

    return False
