# encoding: utf-8

from sqlalchemy import MetaData


def upgrade(migrate_engine):
    metadata = MetaData()
    metadata.bind = migrate_engine
    migrate_engine.execute('''
CREATE TABLE saved_search (
		id text NOT NULL,
		timestamp timestamp without time zone,
		user_id text,
		last_run timestamp without time zone,
		search_string text,
		last_results text[]
	);
    ''')
