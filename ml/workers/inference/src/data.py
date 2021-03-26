from google.cloud import bigquery as bq

def get_data(pid, last_sync):
    client = bq.Client()

    sql = """
        SELECT *
        FROM `phd-project.%s.preprocessed`
        WHERE `date_time` > TIMESTAMP("%s")
    """ % (pid, last_sync)

    df = client.query(sql).to_dataframe()
    return df
