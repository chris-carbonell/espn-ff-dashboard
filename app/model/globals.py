from cube import TemplateContext
from cube_dbt import Dbt

template = TemplateContext()

path_manifest = "/usr/app/manifest.json"

dbt = Dbt.from_file(path_manifest).filter(paths=['d_mrt/a_star/'])

for model in dbt.models:
	print(model.name)

@template.function('dbt_models')
def dbt_models():
	return dbt.models

@template.function('dbt_model')
def dbt_model(name):
	return dbt.model(name)