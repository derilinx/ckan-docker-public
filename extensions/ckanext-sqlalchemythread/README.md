# Thread Fixer

Sqlalchemy can get mortally confused in a forked environment if the
database socket ever winds up getting shared across processes.

This plugin fixes this byt tying a connection to the database to a specific
process.
