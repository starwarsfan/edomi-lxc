USE mysql;

DROP FUNCTION IF EXISTS lib_mysqludf_log_info;
DROP FUNCTION IF EXISTS log_error;

CREATE FUNCTION lib_mysqludf_log_info RETURNS STRING SONAME 'lib_mysqludf_log.so';
CREATE FUNCTION log_error RETURNS STRING SONAME 'lib_mysqludf_log.so';

