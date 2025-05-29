# toyota-data-mesh-demo

1. Run `setup/01_db_setup.sql` in a [worksheet](https://app.snowflake.com/_deeplink/worksheets/?utm_source=&utm_medium=other&utm_campaign=-us-en-all&utm_content=-app-toyota-data-mesh-demo).
2. Upload files to `TOYOTA.ADMIN.SETUP_STAGE`:
    a. The Jinja2 data mesh script, `data_mesh_template.sql`
    b. All of the `.csv` files in `data/*`
3. Set up an S3 connection for Apache Iceberg™ tables by following the instructions [here](https://docs.snowflake.com/en/user-guide/tutorials/create-your-first-iceberg-table#create-an-external-volume) and creating an external volume called `iceberg_external_volume`.
4. Run `setup/02_setup_data_mesh.sql` to create your data mesh.
5. Run `setup/03_insert_toyota_data.sql` to insert sample data.
6. Explore the central ingest, federated domains data mesh!