import datetime
from collections import OrderedDict

import pandas as pd
from google.cloud import bigquery

CLIENT = None
PROJECT_ID = None


def insert_date_range(sql, date_range):
    start, end = date_range
    if start is None and end is None: return sql
    if start is None:
        return sql + ' WHERE `date` <= DATE("%s")' % end
    if end is None:
        return sql + ' WHERE `date` >= DATE("%s")' % start
    return sql + ' WHERE DATE("%s") <= `date` AND `date` <= DATE("%s")' % (start, end)


# define helper fns:
def query_covariate_df_from_gbq(pid, date_range, covariate):
    """
    Query a table from Google BigQuery, via SQL.

    :param pid: patient id (str)
    :param covariate: `heartrate`, `step`, `sleep`
    """
    assert covariate in ['heartrate', 'steps', 'sleep']
    columns = ['Date', 'Time', 'Source', 'Value']

    if covariate != 'sleep':
        sql = """
            SELECT date, time, device, value
            FROM `%s.%s.%s`
        """ % (PROJECT_ID, pid, covariate)
    else:
        sql = """
            SELECT date, time, device, type, value
            FROM `%s.%s.%s`
        """ % (PROJECT_ID, pid, covariate)
        columns = ['Date', 'Time', 'Source', 'Value', 'n_sleep_seconds']

    sql = insert_date_range(sql, date_range)
    df = CLIENT.query(sql).to_dataframe()

    df.columns = columns

    try:
        df['date_time'] = pd.to_datetime(df['date_time'])
    except KeyError:  # if there is SHIT it in the db
        df['date_time'] = df['date_time'] = ['%s %s' % (d, t) for d, t in zip(df['Date'].values, df['Time'].values)]
        df['date_time'] = pd.to_datetime(df['date_time'])
        df.drop(['Date', 'Time'], inplace=True, axis=1)

    #         df = df.set_index('date_time').drop('Test', axis=0).reset_index()
    #         df['date_time'] = pd.to_datetime(df['date_time'])

    df['UserID'] = pid

    if covariate == 'sleep':
        df = df[['UserID', 'Source', 'Value', 'n_sleep_seconds', 'date_time']]
        df['n_sleep_seconds'] = pd.to_numeric(df['n_sleep_seconds'])
    else:
        df = df[['UserID', 'Source', 'Value', 'date_time']]
        df['Value'] = pd.to_numeric(df['Value'])
    return df


def preprocess_covariate_df(pid, pid_df, covariate):
    """
    Preprocess a covariate dataframe:
    - expand data to 1 min resolution
    - expand sleep data

    :param covariate:  `heartrate`, `steps` or `sleep`
    :return:
    """
    pid_df_expanded = []
    # do the following per device and concatenate afterwards.
    for device, ddf in pid_df.groupby('Source'):

        if covariate == 'sleep':

            # apple hk data
            if any(['InBed' in ddf['Value'].unique(), 'Asleep' in ddf['Value'].unique()]):
                ddf.columns = ['uid', 'device', 'sleep', 'date_time']
            elif ddf.empty:
                ddf.columns = ['uid', 'device', 'sleep', 'date_time']
                ddf = ddf.set_index('date_time').resample('T').median().reset_index()
                ddf['sleep'] = 0.

            # fitbit data
            elif any(['rem' in ddf['Value'].unique(),
                      'awake' in ddf['Value'].unique(),
                      'wake' in ddf['Value'].unique(),
                      'deep' in ddf['Value'].unique(),
                      'restless' in ddf['Value'].unique(),
                      'alseep' in ddf['Value'].unique(),
                      'unknown' in ddf['Value'].unique(),
                      ]):
                # we need to expand:
                expanded_dfs = []
                for i, r in ddf.iterrows():
                    n_mins = r['n_sleep_seconds'] // 60
                    df = pd.DataFrame([r['Value']] * n_mins,
                                      index=pd.date_range(r['date_time'].round(freq='T'), periods=n_mins, freq='T'))
                    df['uid'] = r['UserID']
                    expanded_dfs.append(df)
                ddf = pd.concat(expanded_dfs, sort=True, axis=0)
                # delete dublicate indices:
                ddf = ddf.loc[~ddf.index.duplicated(keep='first')]
                ddf.reset_index(inplace=True)
                ddf.columns = ['date_time', 'sleep', 'uid']  # sort out the user ID

            else:  # corrupted fitbit data
                ddf.columns = ['uid', 'device', 'sleep', 'date_time']
                uid = ddf['uid'].unique()[0]
                ddf['sleep'] = 0.
                ddf = ddf.set_index('date_time').resample('T').median().reset_index()
                ddf['uid'] = uid
                ddf['device'] = device
                ddf = ddf[['uid', 'device', 'sleep', 'date_time']]
                ddf['sleep'] = ddf['sleep'].astype(float)

        elif covariate == 'steps':
            ddf.columns = ['uid', 'device', 'steps', 'date_time']
            ddf['steps'] = ddf['steps'].astype(float)
            ddf = ddf.set_index('date_time').resample('T').mean().reset_index()

        elif covariate == 'heartrate':
            ddf.columns = ['uid', 'device', 'heart_rate', 'date_time']
            ddf['heart_rate'] = ddf['heart_rate'].astype(float)
            ddf = ddf.set_index('date_time').resample('T').median().reset_index()

        ddf['uid'] = pid
        ddf['device'] = device
        ddf = ddf.loc[~ddf.index.duplicated(keep='first')]

        pid_df_expanded.append(ddf)

    try:
        pid_df = pd.concat(pid_df_expanded, axis=0)
    except ValueError:
        raise OSError('Empty input files!')
    pid_df = pid_df.set_index(['device', 'date_time']).sort_index()

    return pid_df


def get_PID_df_per_device(pid, dfs, devices=['fitbit'], ndays=1000):
    """
    This returns a pid_df per device in the input .csvs or .jsons

    Possible Devices:
    ['FB-Fitbit',  # Fitbit
     'HK-Connect', # Garmin
               'HK-Health',  # ??
               'HK-iPhone',  # Phone  -> Steps only
               'HK-Motiv',  # motiv ring
               'HK-Apple',   # apple watch
               'HK-Biostrap'  # Biostrap
               ]


    :param pid:
    :return:
    """
    data_per_device = OrderedDict()
    for d in devices:
        p_dfs = []
        for covariate in dfs.keys():
            try:
                p_dfs.append(dfs[covariate].xs(d, level='device', drop_level=True).drop('uid', axis=1))
            except KeyError:
                print('No %s data found for %s' % (covariate, d))
                pdf = pd.DataFrame(columns=[covariate])
                pdf.index.name = 'date_time'
                p_dfs.append(pdf)
        device_df = p_dfs[0].join(p_dfs[1], how='outer')
        device_df = device_df.join(p_dfs[2], how='outer')
        try:
            last_timestamp = device_df.index.values[-1]
            limit = last_timestamp - pd.Timedelta(days=ndays)
            device_df = device_df.loc[limit:last_timestamp]
        except IndexError:
            pass

        device_df['uid'] = pid
        if device_df.index.name != 'date_time':
            device_df.reset_index(inplace=True)
            device_df.set_index('date_time', inplace=True)

        device_df.dropna(subset=['heart_rate', 'steps',
                                 # 'sleep'
                                 ], axis=0, thresh=1, inplace=True)

        device_df[['heart_rate', 'steps']] = device_df[['heart_rate', 'steps']].astype(float)
        data_per_device[d] = device_df

    return data_per_device


def impute_PID_df(in_df, slen, granularity, **kwargs):
    """
    The main preprocessing function.
    IMPORTANT:  As we reasample, we need to binarize the sleep before doing this.

    :param in_df:
    :return:
    """
    uid = in_df['uid'].unique()
    assert len(uid) == 1, 'There must be exactly 1 ID per user.'
    in_df.drop('uid', axis=1)

    in_df = in_df[in_df['heart_rate'] >= 20]  # hard cut-off for HR as HR of 20 is non-realistic

    # binarize the sleep:
    in_df['sleep'] = in_df['sleep'].map(dict([('awake', 0),
                                              ('wake', 0),
                                              ('unknown', 1),
                                              ('light', 1),
                                              ('deep', 1),
                                              ('restless', 1),
                                              ('rem', 1),
                                              ('asleep', 1),
                                              ('Asleep', 1),
                                              ('InBed', 0),
                                              ('NaN', 0)]))

    sleep_df = in_df.copy()
    sleep_df.loc[~sleep_df[['heart_rate', 'steps']].isnull().all(axis=1), 'sleep'] = sleep_df.loc[
        ~sleep_df[['heart_rate', 'steps']].isnull().all(axis=1), 'sleep'].fillna(0.)

    # resample
    in_df = in_df.resample(granularity).median()
    in_df['sleep'] = sleep_df.resample(granularity).max()

    # set the steps to 0, where we have sleep == 1
    in_df.loc[in_df['sleep'] == 1, 'steps'] = 0

    # now extend the index of days that have x% of slen, and fill the nans w/ the average in sleep stratification
    in_df.dropna(thresh=1, axis=0, inplace=True)
    days = []
    for n, d in in_df.groupby(pd.Grouper(freq='D')):
        exclusioncounter = 0
        if len(d.index.values) >= .5 * slen:
            # get the date and reindex:
            date = d.index[0].date()
            # create full range:
            full_day_index = pd.date_range(date, periods=slen, freq=granularity)
            d = d.reindex(full_day_index)
            days.append(d)
        else:
            exclusioncounter += 1
    try:
        in_df = pd.concat(days)
    except ValueError:
        return pd.DataFrame({'Empty': []})

    in_df, _, _ = fill_nans_w_stratified_average(in_df, slen, granularity)

    # This dropna is very important: Drop the hours for which we did not have data!!
    in_df.dropna(axis=0, inplace=True)
    in_df = in_df.groupby(pd.Grouper(freq='D')).filter(lambda x: len(x.index.values) == slen)

    # binarize the sleep:
    s = in_df['sleep']
    in_df.loc[:, 'sleep'] = s.where(s == 0., 1.).values

    assert in_df.shape[0] / slen == float(in_df.shape[0] // slen)

    in_df['uid'] = uid[0]

    # ensure numeric:
    in_df[[c for c in in_df.columns if c != 'uid']] = in_df[[c for c in in_df.columns if c != 'uid']].apply(
        pd.to_numeric)

    return in_df


def get_average_per_granularity(df):
    """
    Calculate the hourly medians and return a df that holds there values.
    :param df: the input df to calculate the hourly medians with
    :return: the df holding the hourly medians
    """
    # median for HR and steps, mean for sleep, is later binarized.
    median_df = df.resample('30T').median()
    median_df.index = [h.time() for h in median_df.index]
    median_df.index.name = 'time_unit'
    median_df = median_df.groupby('time_unit').median()  # here always median
    return median_df


def get_stratified_average_per_granularity(df, slen, granularity, **kwargs):
    """
    Calculate the medians/means per granularity STRATIFIED BY SLEEP and return a df that holds these values.
    :param df: the input df to calculate the hourly medians with
    :return: the df holding the hourly medians
    """
    # stratify by sleep:
    dfs = dict()
    nulls = []

    for n, g in df.groupby('sleep'):
        if pd.isnull(n):
            continue
        # resample (will introduce 'NaNs' if no values
        res_df = g.resample('30T').mean()
        res_df.index = [h.time() for h in res_df.index]
        res_df.index.name = 'time_unit'
        # after the median NaNs migth be reduced but not resolved.
        res_df = res_df.groupby('time_unit').mean()  # here always median

        # now assert that res_df has all hours:
        if res_df.shape[0] < slen:
            time_units = []
            for i in range(0, 24):
                time_units.extend([
                    datetime.time(i, j) for j in range(0, 60, int(granularity.strip('T')))
                ])
            res_df = res_df.reindex(pd.Index(time_units))
            res_df.index.name = 'time_unit'

        nulls.append(sum(res_df.isnull().sum()))

        # fill whats left with the median of the res_df (as this is stratified as well)
        res_df = res_df.fillna(res_df.mean())

        assert sum(res_df.isnull().sum()) == 0

        dfs[n] = res_df

    return dfs, nulls


def fill_nans_w_stratified_average(df, slen, granularity, **kwargs):
    """
    Fills the NaNs by sleep distribution.
    """
    df = df.astype('float')
    impute_count = 0
    # ensure that sleep is binary:
    dfs, nulls = get_stratified_average_per_granularity(df.copy(), slen, granularity)
    imputed = []

    for n, g_df in df.groupby('sleep'):
        if pd.isnull(n):
            imputed.append(g_df)
        complete_missing = g_df.loc[g_df[['steps', 'heart_rate']].isnull().all(axis=1)].index
        for t_idx in complete_missing:
            impute_count += 2  # as we fill 3 values
            h = t_idx.time()
            g_df.loc[t_idx, ['steps', 'heart_rate']] = dfs[n].loc[h, ['steps', 'heart_rate']]

        # now fill the remaining NaNs (we might have had NaNs in the average_df:)
        for c in [c for c in g_df.columns if c != 'sleep']:
            for t in g_df.loc[g_df[c].isnull(), c].index:
                h = t.time()
                g_df.loc[t, c] = dfs[n].loc[h, c]
        imputed.append(g_df)
    imputed.append(df[df['sleep'].isnull()])
    del df
    df = pd.concat(imputed, axis=0)
    del imputed
    df.sort_index(inplace=True)

    # now, where sleep is missing, we fill by the median over the complete data including sleep:
    df = df.astype('float')
    average_df = get_average_per_granularity(df)
    daily_median_df = df.groupby(pd.Grouper(freq='D')).median()  # the medians per day

    complete_missing = df.loc[df[df.columns].isnull().all(axis=1)].index

    for t_idx in complete_missing:
        impute_count += 3  # as we fill 3 values
        h = roundtime(t_idx.to_pydatetime(), 60 * 30).time()
        df.loc[t_idx, :] = average_df.loc[h]
    for c in df.columns:
        for t in df.loc[df[c].isnull(), c].index:
            # h = round_time(t.time(), 30*60)
            h = roundtime(t.to_pydatetime(), 60 * 30).time()
            d = t.date()
            if c != 'sleep':
                if not pd.isnull(average_df.loc[h, c]):
                    df.loc[t, c] = average_df.loc[h, c]
            else:
                df.loc[t, c] = daily_median_df.loc[d, c]

    return df, impute_count, nulls


def roundtime(dt=None, roundTo=60):
    """Round a datetime object to any time laps in seconds
    dt : datetime.datetime object, default now.
    roundTo : Closest number of seconds to round to, default 1 minute.
     Author: Thierry Husson 2012 - Use it as you want but don't blame me.
    """
    if dt == None: dt = datetime.datetime.now()
    seconds = (dt - dt.min).seconds
    # // is a floor division, not a comment on following line:
    rounding = (seconds + roundTo / 2) // roundTo * roundTo
    return dt + datetime.timedelta(0, rounding - seconds, -dt.microsecond)


def upload_to_gpq(df, pid):
    """
    Upload a df of preprocessed data for pid to gbq
    """
    # This pandas implementation is slow! @Diego: rewriting to native GBQ would be much faster!
    df.index.name = 'date_time'
    df.reset_index(inplace=True)
    df.to_gbq('%s.preprocessed' % pid,
              project_id='phd-project',
              chunksize=None,
              if_exists='replace')


def main(pid, date_range, slen, granularity, **kwargs):
    if slen is None: slen = 288
    if granularity is None: granularity = '5T'

    covariate_dfs = OrderedDict()
    for covariate in ['heartrate', 'steps', 'sleep']:
        try:
            covariate_df = query_covariate_df_from_gbq(pid, date_range, covariate)
            covariate_df = preprocess_covariate_df(pid, covariate_df, covariate)
            covariate_dfs[covariate] = covariate_df
        except NotImplementedError:
            covariate_dfs[covariate] = pd.DataFrame(columns=['uid', covariate])
        except OSError:
            return
    pid_device_dfs = get_PID_df_per_device(pid, covariate_dfs, devices=['fitbit'], ndays=100)
    fitbit_df = pid_device_dfs['fitbit']
    imputed_fitbit_df = impute_PID_df(fitbit_df, slen, granularity)

    upload_to_gpq(imputed_fitbit_df, pid)


def setup(project_id):
    global CLIENT, PROJECT_ID
    CLIENT = bigquery.Client()
    PROJECT_ID = project_id


# Must return arguments to be passed onto training.
def preprocess(pid, args):
    setup(args['project_id'])
    main(pid, (args['start_date'], args['end_date']),
         args['slen'], args['granularity'])

    train_args = {}
    return train_args
