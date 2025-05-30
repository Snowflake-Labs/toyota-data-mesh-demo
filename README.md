# toyota-data-mesh-demo

This demo shows how to set up a Central Ingest, Federated Domain data mesh-style architecture on on Snowflake using both Snowflake tables and managed Apache Iceberg™ tables.

1. Run `setup/01_db_setup.sql` in a [worksheet](https://app.snowflake.com/_deeplink/worksheets/?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote&utm_content=-app-toyota-data-mesh-demo).
2. Upload files to `TOYOTA.ADMIN.SETUP_STAGE`
	1. The Jinja2 data mesh script, `data_mesh_template.sql`
	2. All of the `.csv` files in `data/*`
3. Set up an S3 connection for Iceberg tables by following the instructions [here](https://docs.snowflake.com/user-guide/tutorials/create-your-first-iceberg-table?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote&utm_content=-app-toyota-data-mesh-demo#create-an-external-volume) and creating an external volume called `iceberg_external_volume`.
4. Run `setup/02_setup_data_mesh.sql` to create your data mesh.
5. Run `setup/03_insert_toyota_data.sql` to insert sample data.
6. Explore the central ingest, federated domains data mesh!