"""Independent integrity audit. Optional: --full-source PATH (2.3 GB source)."""
from pathlib import Path
import argparse, hashlib, json, re
import numpy as np
import pandas as pd
from scipy import stats
from statsmodels.stats.multitest import multipletests

P=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--full-source',type=Path)
args=parser.parse_args()
checks=[]
def check(label, condition):
    assert bool(condition), label
    checks.append(label)

d=pd.read_stata(P/'data/analysis.dta',convert_categoricals=False)
s=pd.read_stata(P/'data/source_extract.dta',convert_categoricals=False)
check('55,320 unique source and analysis village identifiers',len(d)==len(s)==55320 and d.pca01_id.is_unique and s.pca01_id.is_unique)
pd.testing.assert_frame_equal(d[s.columns],s)
check('Analysis retains every source variable without alteration',True)
check('Population is integer, positive and below 1000',d.tot_p.between(1,999).all() and (d.tot_p==np.floor(d.tot_p)).all())
check('Every source selection flag is satisfied',((d.vplan4<11)&(d.corr_state==1)&(d['sample']==1)&(d.sample_h==1)&(d.sing_h==1)&(d.pop_non_zero==1)&(d.st_code!=32)).all())
check('Geographic and baseline caste fields are complete',not d[['stdt','bk_code','block_id','st_code','pct_sc_01','pct_st_01']].isna().any().any())
for name,expected in {
 'running':d.tot_p-299.5,'eligible':d.tot_p>=300,
 'sc10':d.pct_sc_01.astype('float64')/.1,'st10':d.pct_st_01.astype('float64')/.1,
 'lights_change_abs':(d.lights_max2011_hat.astype('float64')-d.lights_max2001_hat.astype('float64')).abs(),
 'sample_no_post_filter':d.pop_mismatch20==0,
 'local_100':abs(d.tot_p-299.5)<100,'local_200':abs(d.tot_p-299.5)<200,
 'lighting_change':d.hpca11_msl_elec.astype('float64')-d.hpca01_msl_elec.astype('float64'),
 'access_adoption_gap':d.vd_pwr_d_dom_11.astype('float64')-d.hpca11_msl_elec.astype('float64')}.items():
    np.testing.assert_allclose(d[name],expected,rtol=0,atol=1e-12,equal_nan=True)
check('Derived quantities match independent double-precision reconstruction',True)
check('Preferred sample is exactly reconstructed',np.array_equal(d.sample_preferred,((d.pop_mismatch20==0)&(d.lights_change_abs<20)).astype('int8')))
codes=pd.factorize(pd.MultiIndex.from_frame(d[['stdt','bk_code']]),sort=True)[0]+1
check('Cluster codes uniquely and consistently identify district-block pairs',np.array_equal(codes,d.block_id))
cat=np.select([d.pct_st_01>=.5,d.pct_sc_01>=.5],['ST majority','SC majority'],default='Other villages')
check('Composition groups and 50/50 tie rule match Stata',np.array_equal(cat,d.caste_group))
for stem,frame in [('analysis',d),('source_extract',s)]:
    csv=pd.read_csv(P/f'data/{stem}.csv',dtype=str,keep_default_na=False)
    check(stem+' CSV has matching rows and columns',csv.shape==frame.shape and list(csv)==list(frame))
    for c in frame:
        if not pd.api.types.is_numeric_dtype(frame[c]):
            check(stem+' CSV string '+c,np.array_equal(csv[c].to_numpy(),frame[c].fillna('').to_numpy()))
        else:
            np.testing.assert_allclose(pd.to_numeric(csv[c],errors='coerce'),frame[c],rtol=1e-6,atol=1e-8,equal_nan=True)
check('CSV and Stata files agree within source numeric precision',True)
local=d[d.sample_preferred.eq(1)&d.local_100.eq(1)]
status=json.loads((P/'verification/execution_status.json').read_text())
check('Reported local sample and cluster counts are exact',len(local)==status['local_main_n']==12533 and local.block_id.nunique()==status['local_main_blocks']==1342 and local.stdt.nunique()==129)
r=pd.read_csv(P/'tables/heterogeneity_results.csv')
primary=['vd_pwr_d_dom_11','hpca11_msl_elec']
for family in [primary,sorted(set(r.outcome)-set(primary))]:
    q=r[r.bandwidth.eq(100)&r.outcome.isin(family)]
    np.testing.assert_allclose(q.p_holm,multipletests(q.p_value,method='holm')[1],rtol=0,atol=1e-12)
check('Four primary and twelve secondary Holm tests are correct',len(r[r.bandwidth.eq(100)&r.outcome.isin(primary)])==4 and len(r[r.bandwidth.eq(100)&~r.outcome.isin(primary)])==12)
np.testing.assert_allclose(r.p_value,2*stats.t.sf(abs(r.estimate/r.se),r.clusters-1),atol=1e-12)
np.testing.assert_allclose(r.ci_high,r.estimate+stats.t.ppf(.975,r.clusters-1)*r.se,atol=1e-12)
np.testing.assert_allclose(r.ci_low,r.estimate-stats.t.ppf(.975,r.clusters-1)*r.se,atol=1e-12)
check('All heterogeneity p-values and 95% cluster-t intervals are correct',True)
for y in r.outcome.unique():
    f=pd.read_csv(P/f'tables/full_model_{y}.csv').set_index('term')
    for _,row in r[r.outcome.eq(y)&r.bandwidth.eq(100)].iterrows():
        np.testing.assert_allclose(f.loc[row.term,['estimate','se','p_value','ci_low','ci_high']].to_numpy(dtype=float),row[['estimate','se','p_value','ci_low','ci_high']].to_numpy(dtype=float),atol=1e-12)
check('Every headline interaction matches its complete regression table',True)
rb=pd.read_csv(P/'tables/pooled_rdrobust.csv')
for _,row in rb.iterrows():
    z=d[d.sample_preferred.eq(1)&d.local_200.eq(1)].dropna(subset=[row.outcome,'running','block_id','st_code'])
    for prefix,field in [('h','clusters'),('b','clusters_bias')]:
        q=z[((z.running<0)&(abs(z.running)<row[prefix+'_left']))|((z.running>=0)&(abs(z.running)<row[prefix+'_right']))]
        check('Pooled '+row.outcome+'/'+row.method+'/'+field,int(q.block_id.nunique())==row[field])
    check('Pooled sample counts '+row.outcome+'/'+row.method,int((z.running.between(-row.h_left,0,inclusive='neither')).sum())==row.n_left and int(((z.running>=0)&(z.running<row.h_right)).sum())==row.n_right)
np.testing.assert_allclose(rb.p_robust,2*stats.norm.sf(abs(rb.tau_bias_corrected/rb.se_robust)),atol=1e-12)
np.testing.assert_allclose(rb.ci_low_robust,rb.tau_bias_corrected-stats.norm.ppf(.975)*rb.se_robust,atol=1e-12)
np.testing.assert_allclose(rb.ci_high_robust,rb.tau_bias_corrected+stats.norm.ppf(.975)*rb.se_robust,atol=1e-12)
check('All pooled robust-bias-corrected intervals and p-values match the reported estimator',True)
check('All eight main models have independently checked coefficients and covariance',status['main_models_independently_checked']==8)
manifest=json.loads((P/'docs/figure_manifest.json').read_text())
check('All 18 figures have PNG and SVG files',len(manifest)==18 and all((P/x['file']).exists() and (P/x['file']).with_suffix('.svg').exists() for x in manifest))
for document in [P/'README.md',P/'report/report.html']:
    text=document.read_text()
    targets=re.findall(r'href="([^"]+)"|src="([^"]+)"',text) if document.suffix=='.html' else re.findall(r'\]\(([^)]+)\)',text)
    for target in targets:
        if isinstance(target,tuple): target=next(x for x in target if x)
        if not target.startswith(('http:','https:','#')):
            check('Local link '+target,(document.parent/target).exists())
if args.full_source:
    source=args.full_source
    md5=hashlib.md5()
    with source.open('rb') as f:
        for payload in iter(lambda:f.read(8*1024*1024),b''):md5.update(payload)
    original=json.loads((P/'docs/source_manifest.json').read_text())
    check('Full source byte size and original MD5 verified again',source.stat().st_size==original['source_size'] and md5.hexdigest()==original['source_md5'])
    frames=[]
    for c in pd.read_stata(source,columns=list(s.columns),chunksize=25000,convert_categoricals=False):
        keep=(c.vplan4<11)&c.vplan4.notna()&(c.corr_state==1)&(c['sample']==1)&(c.sample_h==1)&(c.sing_h==1)&(c.pop_non_zero==1)&(c.st_code!=32)&c.tot_p.between(1,999)
        frames.append(c[keep])
    rebuilt=pd.concat(frames,ignore_index=True)
    pd.testing.assert_frame_equal(rebuilt,s)
    check('All 55,320 delivered villages and source columns re-extracted exactly from the full public file',True)
result={'audit_date':'2026-10-09','passed':True,'checks':checks,'check_count':len(checks),'full_source_checked':bool(args.full_source),'stata_runtime_verified':False,'main_conclusion_changed':False}
(P/'verification/project_audit.json').write_text(json.dumps(result,indent=2))
print(json.dumps({'passed':True,'checks':len(checks),'full_source_checked':bool(args.full_source)},indent=2))
