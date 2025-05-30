--!jinja2
--!https://medium.com/snowflake/practical-implementation-of-federated-architecture-with-snowflake-features-154af30792a7
{% set environment = environments.split(';') %}

{% for item in environment %}
    {% macro create_dbs(env, dbname) %}  
        USE ROLE {{ env }}_SYSADMIN;
        CREATE DATABASE IF NOT EXISTS {{ env }}_{{ dbname }}_db;
        USE DATABASE {{ env }}_{{ dbname }}_db;
        ALTER DATABASE {{ env }}_{{ dbname }}_db SET TAG ADMIN_DB.ADMIN_TAGS.ENVIRONMENT = {{ ev }};
        CREATE DATABASE ROLE IF NOT EXISTS {{ env }}_{{ dbname }}_db_r;
        CREATE DATABASE ROLE IF NOT EXISTS {{ env }}_{{ dbname }}_db_w;
        CREATE DATABASE ROLE IF NOT EXISTS {{ env }}_{{ dbname }}_db_c;
        GRANT DATABASE ROLE {{ env }}_{{ dbname }}_db_r TO DATABASE ROLE {{ item }}_{{ dbname }}_db_w;
        GRANT DATABASE ROLE {{ env }}_{{ dbname }}_db_w TO DATABASE ROLE {{ item }}_{{ dbname }}_db_c;
        GRANT DATABASE ROLE {{ env }}_{{ dbname }}_db_c TO ROLE {{ item }}_SYSADMIN;  
        GRANT ALL ON DATABASE {{ env }}_{{ dbname }}_db TO DATABASE ROLE {{ item }}_{{ dbname }}_db_c;
        GRANT MODIFY, MONITOR ON DATABASE {{ env }}_{{ dbname }}_db TO DATABASE ROLE {{ item }}_{{ dbname }}_db_w;
        GRANT MONITOR ON DATABASE {{ env }}_{{ dbname }}_db TO DATABASE ROLE {{ item }}_{{ dbname }}_db_r;
    {% endmacro %}
    {% macro create_schema(env,dbname, schema) %}  
        USE ROLE {{ env }}_SYSADMIN;
        USE DATABASE {{ env }}_{{ dbname }}_db;
        CREATE SCHEMA IF NOT EXISTS {{ schema }}_sch WITH MANAGED ACCESS;
        CREATE DATABASE ROLE IF NOT EXISTS {{ env }}_{{ dbname }}_{{ schema }}_r;
        CREATE DATABASE ROLE IF NOT EXISTS {{ env }}_{{ dbname }}_{{ schema }}_w;
        CREATE DATABASE ROLE IF NOT EXISTS {{ env }}_{{ dbname }}_{{ schema }}_c;
        GRANT DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_r TO DATABASE ROLE {{ env }}_{{ dbname }}_db_r;
        GRANT DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_w TO DATABASE ROLE {{ env }}_{{ dbname }}_db_w;
        GRANT DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_c TO DATABASE ROLE {{ env }}_{{ dbname }}_db_c;
        GRANT OWNERSHIP ON SCHEMA {{ env }}_{{ dbname }}_db.{{ schema }}_sch TO DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_c REVOKE CURRENT GRANTS;
        GRANT DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_w TO DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_c;
        GRANT DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_r TO DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_w;
        GRANT MONITOR, USAGE, ADD SEARCH OPTIMIZATION ON SCHEMA  {{ env }}_{{ dbname }}_db.{{ schema }}_sch TO DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_w;
        GRANT ALL ON FUTURE TABLES IN SCHEMA {{ env }}_{{ dbname }}_db.{{ schema }}_sch TO DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_c;
        GRANT ALL ON FUTURE VIEWS IN SCHEMA {{ env }}_{{ dbname }}_db.{{ schema }}_sch TO DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_c;
        GRANT SELECT,INSERT,UPDATE,DELETE,TRUNCATE ON FUTURE TABLES IN SCHEMA {{ env }}_{{ dbname }}_db.{{ schema }}_sch TO DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_w;
        GRANT SELECT, REFERENCES ON FUTURE VIEWS IN SCHEMA {{ env }}_{{ dbname }}_db.{{ schema }}_sch TO DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_w;
        GRANT SELECT ON FUTURE VIEWS IN SCHEMA {{ env }}_{{ dbname }}_db.{{ schema }}_sch TO DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_r;
        GRANT SELECT ON FUTURE TABLES IN SCHEMA {{ env }}_{{ dbname }}_db.{{ schema }}_sch TO DATABASE ROLE {{ env }}_{{ dbname }}_{{ schema }}_r;
    {% endmacro %}
    {% macro create_functional_roles(env, databaseroleprefix, functionroleprefix,dbname) %}  
        USE ROLE {{ env }}_USERADMIN;
        CREATE ROLE IF NOT EXISTS {{ functionroleprefix }}_CICD;
        GRANT ROLE {{ functionroleprefix }}_CICD TO ROLE {{ env }}_SYSADMIN;
        CREATE ROLE IF NOT EXISTS {{ functionroleprefix }}_ETL;
        GRANT ROLE {{ functionroleprefix }}_ETL TO ROLE {{ functionroleprefix }}_CICD;
        CREATE ROLE IF NOT EXISTS {{ functionroleprefix }}_ANALYST;
        GRANT ROLE {{ functionroleprefix }}_ANALYST TO ROLE {{ functionroleprefix }}_ETL;
    {% endmacro %}
    {% macro grant_database_roles_to_functional_roles(env, databaseroleprefix,functionroleprefix) %}  
        USE ROLE {{ env }}_SYSADMIN;
        USE DATABASE {{ env }}_{{ databaseroleprefix }}_db;
        GRANT DATABASE ROLE {{ env }}_{{ databaseroleprefix }}_db_c TO ROLE {{ functionroleprefix }}_CICD;
        GRANT DATABASE ROLE {{ env }}_{{ databaseroleprefix }}_db_w TO ROLE {{ functionroleprefix }}_ETL;
        GRANT DATABASE ROLE {{ env }}_{{ databaseroleprefix }}_db_r TO ROLE {{ functionroleprefix }}_ANALYST;
    {% endmacro %}
    {% macro create_warehouse(env, warehousenameprefix,functionroleprefix) %}  
        USE ROLE {{ env }}_USERADMIN;
        CREATE ROLE IF NOT EXISTS {{ warehousenameprefix }}_wh_usg;
        CREATE ROLE IF NOT EXISTS {{ warehousenameprefix }}_wh_opr;
        CREATE ROLE IF NOT EXISTS {{ warehousenameprefix }}_wh_adm;
        GRANT ROLE {{ warehousenameprefix }}_wh_usg TO ROLE  {{ warehousenameprefix }}_wh_opr;
        GRANT ROLE {{ warehousenameprefix }}_wh_opr TO ROLE  {{ warehousenameprefix }}_wh_adm;
        GRANT ROLE {{ warehousenameprefix }}_wh_adm TO ROLE {{ env }}_SYSADMIN;
        USE ROLE {{ env }}_SYSADMIN;
        CREATE WAREHOUSE IF NOT EXISTS {{ warehousenameprefix }}_wh  WAREHOUSE_SIZE = 'X-Small' AUTO_RESUME = true AUTO_SUSPEND = 300 ENABLE_QUERY_ACCELERATION = false WAREHOUSE_TYPE = 'STANDARD' MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 1 SCALING_POLICY = 'STANDARD' INITIALLY_SUSPENDED = true;
        ALTER WAREHOUSE {{ warehousenameprefix }}_wh SET TAG ADMIN_DB.ADMIN_TAGS.ENVIRONMENT =   {{ ev }};
        GRANT USAGE, MONITOR ON WAREHOUSE {{ warehousenameprefix }}_wh to role {{ warehousenameprefix }}_wh_usg;
        GRANT OPERATE, MODIFY ON  WAREHOUSE {{ warehousenameprefix }}_wh to role {{ warehousenameprefix }}_wh_opr;
        GRANT ALL ON  WAREHOUSE {{ warehousenameprefix }}_wh to role {{ warehousenameprefix }}_wh_adm;
        USE ROLE {{ env }}_USERADMIN;
        GRANT ROLE {{ warehousenameprefix }}_wh_usg TO  ROLE {{ functionroleprefix }}_ANALYST;
        GRANT ROLE {{ warehousenameprefix }}_wh_opr TO  ROLE {{ functionroleprefix }}_ETL;
        GRANT ROLE {{ warehousenameprefix }}_wh_adm TO  ROLE {{ functionroleprefix }}_CICD;
    {% endmacro %}
    {% set ev ="'"+ item +"'" %}
    USE ROLE ACCOUNTADMIN;
    CREATE DATABASE IF NOT EXISTS ADMIN_DB;
    USE DATABASE ADMIN_DB;
    CREATE SCHEMA IF NOT EXISTS ADMIN_OPS;
    CREATE SCHEMA IF NOT EXISTS ADMIN_TAGS;
    USE SCHEMA ADMIN_TAGS;
    CREATE TAG IF NOT EXISTS ENVIRONMENT ALLOWED_VALUES 'DEV','QA','PREPROD','PROD' COMMENT = 'Environments tag';
    CREATE SCHEMA IF NOT EXISTS ADMIN_POLICY;
    USE ROLE USERADMIN;
    CREATE ROLE IF NOT EXISTS {{ item }}_SYSADMIN;
    USE ROLE ACCOUNTADMIN;
    GRANT ROLE {{ item }}_SYSADMIN TO ROLE SYSADMIN;
    GRANT CREATE DATABASE, CREATE WAREHOUSE,CREATE INTEGRATION,CREATE SHARE,EXECUTE ALERT,EXECUTE DATA METRIC FUNCTION,EXECUTE MANAGED ALERT,EXECUTE MANAGED TASK,EXECUTE TASK,IMPORT SHARE,MONITOR EXECUTION, MONITOR USAGE,APPLY MASKING POLICY,APPLY ROW ACCESS POLICY,APPLY AGGREGATION POLICY,APPLY PROJECTION POLICY,APPLY TAG  ON ACCOUNT TO ROLE {{ item }}_SYSADMIN ;
    USE ROLE {{ item }}_SYSADMIN;
    CREATE WAREHOUSE IF NOT EXISTS {{ item }}_ADMIN_WH COMMENT = 'VIRTUAL WAREHOUSE TO PERFORM ADMINISTRATION' WAREHOUSE_SIZE = 'X-Small' AUTO_RESUME = true AUTO_SUSPEND = 300 ENABLE_QUERY_ACCELERATION = false WAREHOUSE_TYPE = 'STANDARD' MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 1 SCALING_POLICY = 'STANDARD' initially_suspended=true;
    USE ROLE USERADMIN;
    CREATE ROLE IF NOT EXISTS {{ item }}_USERADMIN;
    GRANT ROLE {{ item }}_USERADMIN TO ROLE USERADMIN;
    USE ROLE ACCOUNTADMIN;
    GRANT CREATE ROLE ON ACCOUNT TO ROLE  {{ item }}_USERADMIN;
    {% set whsch = createwarehousesforsources+";"+createwarehousesfordp %}
    {% if model == 'centralIntegrationfeddataproducts' %}
        {% set databases = "SOURCE;INTEGRATION;CURATED;"+domains %}
        {% set intnames = "INTEGRATION" %}
        {% set whdb = domains %}
        {% set curnames = "CURATED" %}
        {% set dbschgroups = "SOURCE^"+sourcenames+"*INTEGRATION^"+intnames+"*CURATED^"+curnames+"*"+dpnames %}
    {% elif model == 'centralingestcoarsedomainint' %}
        {% set coarsegraindom = coarsegraindom %}
        {% set intnames = "INTEGRATION;CURATED" %}
        {% set whdb = coarsegraindom+";"+domains %}
        {% set databases = "SOURCE;"+coarsegraindom+";"+domains %}
        {% set coarsegraindom = coarsegraindom.replace(";","^INTEGRATION;CURATED*")  %}
        {% set dbschgroups = "SOURCE^"+sourcenames+"*"+coarsegraindom+"^"+intnames+"*"+dpnames %}
    {% elif model == 'centralingestfeddomains' %}
        {% set whdb = domains %}
        {% set intnames = "STAGE;INTEGRATION;CURATED" %}
        {% set domains = domains.replace(";","^STAGE;INTEGRATION;CURATED*")  %}
        {% set dbschgroups = "SOURCE^"+sourcenames+"*"+domains+"^"+intnames+"*"+dpnames %}
    {% elif model == 'federated' %}
        {% set intnames = "INTEGRATION;CURATED;"+sourcenames %}
        {% set whdb = domains %}
        {% set databases = domains %}
        {% set dbschgroups = domains+"^"+intnames+"*"+dpnames %}
    {% endif %}

    {{ create_functional_roles(item,item,item,item) }}
    {{ create_warehouse(item,item,item) }}

    {% set dbschgroups = dbschgroups.split('*') %}
    {% for group in dbschgroups %}
        {% set db, schemas = group.split('^') %}
            {{ create_dbs(item, db) }}
            {% if db in whdb %}
                {{ create_functional_roles(item,db+"_db",item+"_"+db,db) }}
                {{ grant_database_roles_to_functional_roles(item,db,item+"_"+db) }}
                {{ create_warehouse(item,item+"_"+db,item+"_"+db) }}
            {% else %}
                {{ grant_database_roles_to_functional_roles(item,db,item) }}
            {% endif %}
            {% set schems = schemas.split(';') %}  
            {% for schem in schems %}
                    {{ create_schema(item,db,schem) }}
                    {% if schem in whsch %}
                        {{ create_functional_roles(item,db+"_"+schem,item+"_"+db+"_"+schem, db) }}
                        {{ create_warehouse(item, item+"_"+db+"_"+schem,item+"_"+db+"_"+schem) }}
                    {% endif %}
            {% endfor %}
    {% endfor %}
{%endfor %}