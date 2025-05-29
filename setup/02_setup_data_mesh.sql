USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@"TOYOTA"."ADMIN"."SETUP_STAGE"/data_mesh_template.sql'
USING (model=> 'centralingestfeddomains', environments=> 'DEV', sourcenames=> 'CCD;CON',domains=> 'RND;QUALITY', dpnames=> 'RND^CRASHDET*QUALITY^EDER',createwarehousesforsources=>'CCD',createwarehousesfordp=>'CRASHDET');