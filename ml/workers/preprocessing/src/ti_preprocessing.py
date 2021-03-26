from google.cloud import bigquery as bq

def ti_preprocess(pid, study, args):
    bqCL = bq.Client()

    copy_table_with_distinct(bqCL, pid, study, args, 'Heartrate')
    copy_table_with_distinct(bqCL, pid, study, args, 'Step')
#    copy_table_with_distinct(bqCL, pid, study, args, 'Sleep')

    trainfer_args = {}
    return trainfer_args


def copy_table_with_distinct(bqCL, pid, study, args, type):
    # Remove duplicates.
    sql = """
        SELECT DISTINCT *
        FROM %s.%s.%s
    """ % (args['project_id'], pid, type)
    df = bqCL.query(sql).to_dataframe()

    # Upload preprocessed table.
    df.to_gbq('%s.%s_%s' % (pid, study, type),
              project_id = args['project_id'],
              chunksize = None,
              if_exists = 'replace')
