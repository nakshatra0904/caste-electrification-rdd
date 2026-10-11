"""Audit and extract real RGGVY records; keep the full archive outside the delivered data/."""
from pathlib import Path
import sys, json, hashlib, zipfile
from datetime import datetime
ROOT = Path(__file__).resolve().parents[1]
import pandas as pd
import numpy as np

PROJECT = ROOT
for folder in ['data','stata','tables','figures','report','verification','docs']:
    (PROJECT / folder).mkdir(parents=True, exist_ok=True)
source = ROOT / 'raw/panel_dataset_full.dta'
if not source.exists():
    archive = ROOT / 'raw/rggvy_source.zip'
    with zipfile.ZipFile(archive) as z:
        member = next(x for x in z.infolist() if x.filename.endswith('panel_dataset_full.dta'))
        with z.open(member) as raw, source.open('wb') as out:
            while payload := raw.read(1024*1024):
                out.write(payload)

metadata = json.loads((ROOT / 'docs/source_archive_metadata.json').read_text(encoding='utf-8-sig'))
entry = next(x['dataFile'] for x in metadata['data']['latestVersion']['files'] if x['dataFile']['id']==7887967)
digest = hashlib.md5()
with source.open('rb') as stream:
    while payload := stream.read(1024*1024):
        digest.update(payload)
assert source.stat().st_size == entry['filesize']
assert digest.hexdigest() == entry['md5'], 'Source checksum mismatch'

columns = ['pca01_id','vd01_id','pca11_id','vd11_id','state','st_code','district','stdt','bk_code',
           'block','village','tot_p','tot_p11','tot_f','tot_f11','no_hh','pct_sc_01','pct_st_01',
           'lit_p_01','pct_06_01','work_p_01','work_f_01','work_p_11','work_f_11',
           'work_pooled_ot_p_01','work_pooled_ot_f_01','work_pooled_ot_p_11','work_pooled_ot_f_11',
           'hpca01_msl_elec','hpca11_msl_elec','vd_pwr_d_dom_01','vd_pwr_d_dom_11',
           'vd_pwr_d_any_01','vd_pwr_d_any_11','vdp_pwr_h_dom_avg_11',
           'vdp_pwr_d_com_11','vd_pwr_d_all_11','vdp_pwr_h_com_avg_11',
           'vplan4','corr_state','sample','sample_h','sing_h','pop_non_zero','pop_mismatch20',
           'lights_max2001_hat','lights_max2011_hat'] + [f'lights_max{yr}' for yr in range(1998,2014)]
reader = pd.io.stata.StataReader(source)
labels = reader.variable_labels()
available = set(labels)
missing_columns = sorted(set(columns)-available)
if missing_columns:
    raise ValueError(f'Missing required source variables: {missing_columns}')

frames = []
flow = {'source_records':0,'first_wave':0,'valid_geography':0,'nightlights_match':0,
        'habitation_match':0,'single_habitation':0,'positive_population':0,'non_kerala':0,
        'population_under_1000':0}
for chunk in pd.read_stata(source, columns=columns, chunksize=25000, convert_categoricals=False):
    flow['source_records'] += len(chunk)
    restrictions = [('first_wave',chunk.vplan4.notna() & (chunk.vplan4<11)),
                    ('valid_geography',chunk.corr_state==1),('nightlights_match',chunk['sample']==1),
                    ('habitation_match',chunk.sample_h==1),('single_habitation',chunk.sing_h==1),
                    ('positive_population',chunk.pop_non_zero==1),('non_kerala',chunk.st_code!=32),
                    ('population_under_1000',chunk.tot_p.notna() & (chunk.tot_p>0) & (chunk.tot_p<1000))]
    keep = pd.Series(True,index=chunk.index)
    for name, restriction in restrictions:
        keep &= restriction
        flow[name] += int(keep.sum())
    frames.append(chunk.loc[keep].copy())
raw = pd.concat(frames, ignore_index=True)
assert raw.pca01_id.notna().all() and raw.pca01_id.is_unique
raw.to_stata(PROJECT/'data/source_extract.dta',write_index=False,version=118,
             variable_labels={k:v[:80] for k,v in labels.items() if k in raw})
raw.to_csv(PROJECT/'data/source_extract.csv',index=False)

d = raw.copy()
assert d.tot_p.mod(1).eq(0).all()
for name in ['pct_sc_01','pct_st_01','hpca01_msl_elec','hpca11_msl_elec',
             'work_p_01','work_f_01','work_p_11','work_f_11',
             'work_pooled_ot_p_01','work_pooled_ot_f_01','work_pooled_ot_p_11','work_pooled_ot_f_11']:
    assert d[name].dropna().between(0,1).all(), f'Unexpected units/range for {name}'
assert (d.pct_sc_01+d.pct_st_01).dropna().le(1.000001).all()
for name in ['vd_pwr_d_dom_01','vd_pwr_d_dom_11','vd_pwr_d_any_01','vd_pwr_d_any_11','vdp_pwr_d_com_11','vd_pwr_d_all_11']:
    assert set(d[name].dropna().unique()).issubset({0,1})

d['running'] = d.tot_p - 299.5
d['eligible'] = (d.tot_p>=300).astype('int8')
d['sc10'] = d.pct_sc_01.astype('float64')/0.1
d['st10'] = d.pct_st_01.astype('float64')/0.1
d['sc_majority'] = np.where(d.pct_sc_01.notna(),(d.pct_sc_01>=.5).astype(float),np.nan)
d['st_majority'] = np.where(d.pct_st_01.notna(),(d.pct_st_01>=.5).astype(float),np.nan)
d['caste_group'] = np.select([d.pct_st_01>=.5,d.pct_sc_01>=.5],['ST majority','SC majority'],default='Other villages')
d.loc[d.pct_sc_01.isna() | d.pct_st_01.isna(),'caste_group'] = 'Missing composition'
d['block_id'] = pd.factorize(pd.MultiIndex.from_frame(d[['stdt','bk_code']]),sort=True)[0]+1
d['lights_change_abs'] = (d.lights_max2011_hat.astype('float64')-d.lights_max2001_hat.astype('float64')).abs()
d['sample_no_post_filter'] = (d.pop_mismatch20==0).astype('int8')
d['sample_preferred'] = ((d.pop_mismatch20==0) & (d.lights_change_abs<20)).astype('int8')
d['local_200'] = (d.running.abs()<200).astype('int8')
d['local_100'] = (d.running.abs()<100).astype('int8')
d['lighting_change'] = d.hpca11_msl_elec.astype('float64')-d.hpca01_msl_elec.astype('float64')
d['access_adoption_gap'] = d.vd_pwr_d_dom_11.astype('float64')-d.hpca11_msl_elec.astype('float64')
derived_labels = {'running':'2001 population minus 299.5 (persons)',
 'eligible':'RGGVY eligibility: 2001 Census population >=300',
 'sc10':'2001 SC share, units of 10 percentage points',
 'st10':'2001 ST share, units of 10 percentage points',
 'block_id':'Unique state-district-block cluster identifier',
 'caste_group':'2001 caste composition: ST>=50%, SC>=50%, or other',
 'sample_preferred':'Author sample: match quality and abs lights change <20',
 'sample_no_post_filter':'Match quality sample without post-policy lights filter',
 'access_adoption_gap':'2011 domestic village access minus HH electric-lighting share',
 'lighting_change':'2011 minus 2001 HH electric-lighting share'}
all_labels = {**{k:v[:80] for k,v in labels.items() if k in d},**derived_labels}
d.to_stata(PROJECT/'data/analysis.dta',write_index=False,version=118,variable_labels=all_labels)
d.to_csv(PROJECT/'data/analysis.csv',index=False)
dictionary=[]
for c in d:
    series=d[c]
    dictionary.append({'variable':c,'description':all_labels.get(c,c),
                       'type':str(series.dtype),'missing_n':int(series.isna().sum()),
                       'source':'derived' if c not in raw else 'RGGVY archive file 7887967'})
pd.DataFrame(dictionary).to_csv(PROJECT/'docs/data_dictionary.csv',index=False)
flow['preferred_sample']=int(d.sample_preferred.sum())
flow['preferred_local_200']=int((d.sample_preferred.eq(1)&d.local_200.eq(1)).sum())
flow['preferred_local_100']=int((d.sample_preferred.eq(1)&d.local_100.eq(1)).sum())
pd.DataFrame({'stage':flow.keys(),'records':flow.values()}).to_csv(PROJECT/'tables/sample_flow.csv',index=False)
manifest={'doi':'10.7910/DVN/APWICK','archive_file_id':7887967,'archive_filename':entry['filename'],
 'archive_version':str(metadata['data']['latestVersion']['versionNumber'])+'.'+str(metadata['data']['latestVersion']['versionMinorNumber']),
 'retrieval_started':'2026-10-08','download_completed':datetime.now().astimezone().isoformat(),
 'source_size':entry['filesize'],'source_md5':digest.hexdigest(),
 'license':metadata['data']['latestVersion'].get('license'),'source_n':flow['source_records'],
 'extract_n':len(raw),'extract_columns':columns,'source_url':'https://dataverse.harvard.edu/api/access/datafile/7887967'}
(PROJECT/'docs/source_manifest.json').write_text(json.dumps(manifest,indent=2))
(ROOT/'verification/audit_summary.json').write_text(json.dumps(flow,indent=2))
print(json.dumps(flow,indent=2),flush=True)
print(d.loc[d.sample_preferred.eq(1)&d.local_100.eq(1)].groupby(['caste_group','eligible']).size().to_string(),flush=True)
print('Audit passed; real source extract and analysis data saved.',flush=True)
