import ckan.plugins as plugins

##
## This plugin hooks the sqlalchemy model when configuration happens
## to allow it to be safe in a forked/multithreaded environment.
##


class SqlalchemyThreadPlugin(plugins.SingletonPlugin):
    pass


from sqlalchemy import event
from sqlalchemy import exc
from sqlalchemy.engine import Engine

import logging
log = logging.getLogger(__name__)
log.setLevel(logging.INFO)


import os

@event.listens_for(Engine, "connect")
def connect(dbapi_connection, connection_record):
    log.debug('connect listener fired for %s' % connection_record.info)
    connection_record.info['pid'] = os.getpid()

@event.listens_for(Engine, "checkout")
def checkout(dbapi_connection, connection_record, connection_proxy):
    log.debug('checkout listener fired for %s' % connection_record.info)
    pid = os.getpid()
    if connection_record.info.get('pid', None) != pid:
        log.info('checkout recycling connection in new pid %s, orig: %s' %(
            pid, connection_record.info.get('pid', None)))
        connection_record.connection = connection_proxy.connection = None
        raise exc.DisconnectionError(
                "Connection record belongs to pid %s, "
                "attempting to check out in pid %s" %
                (connection_record.info.get('pid', None), pid)
        )
