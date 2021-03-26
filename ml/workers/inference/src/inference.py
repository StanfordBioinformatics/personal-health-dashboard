import mlflow.sklearn
import mlflow

import os
# using Thore's login since I know it still works!
MLFLOW_USERNAME = 'tbuergel'
MLFLOW_PASSWORD = 'tbuergel'
os.environ["MLFLOW_TRACKING_USERNAME"] = MLFLOW_USERNAME
os.environ["MLFLOW_TRACKING_PASSWORD"] = MLFLOW_PASSWORD

MLFLOW_VM_URL = 'http://10.138.0.58'

def load_registered_model(model_name):
    mlflow.set_tracking_uri(MLFLOW_VM_URL)
    loaded_model = mlflow.sklearn.load_model('models:/%s/Production' % model_name)
    print('Loaded %s!' % model_name)


# Not currently needed. Contingency measure.
def get_source_location_for_production_model():
    model_name = 'diabetes-detector'
    client = mlflow.tracking.MlflowClient(tracking_uri = MLFLOW_VM_URL)
    rm = client.get_registered_model(model_name)
    return [version.source for version in rm.latest_versions if version.current_stage == 'Production']
