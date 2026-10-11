"""Executed verification analysis matching the accompanying Stata programs."""
from pathlib import Path
import sys, json, warnings, contextlib, io, textwrap
ROOT=Path(__file__).resolve().parents[1]
import numpy as np
import pandas as pd
import scipy.stats as stats
import statsmodels.api as sm
from statsmodels.stats.multitest import multipletests
from rdrobust import rdrobust
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

P=ROOT
d=pd.read_stata(P/'data/analysis.dta',convert_categoricals=False)
T=P/'tables'; F=P/'figures'
PRIMARY=['vd_pwr_d_dom_11','hpca11_msl_elec']
EMPLOYMENT=['work_p_11','work_f_11','work_pooled_ot_p_11','work_pooled_ot_f_11']
PRODUCTIVE=['vdp_pwr_d_com_11','vd_pwr_d_all_11']
SECONDARY=EMPLOYMENT+PRODUCTIVE
NAMES={'vd_pwr_d_dom_11':'Village domestic electricity availability',
 'hpca11_msl_elec':'Households using electric lighting',
 'hpca01_msl_elec':'Households using electric lighting, 2001',
 'work_p_11':'All work participation','work_f_11':'Female work participation',
 'work_pooled_ot_p_11':'Other (non-agricultural) work participation',
 'work_pooled_ot_f_11':'Female other (non-agricultural) work',
 'vd_pwr_d_dom_01':'Village domestic electricity availability, 2001',
 'pct_sc_01':'Scheduled Caste population share, 2001',
 'pct_st_01':'Scheduled Tribe population share, 2001',
 'lit_p_01':'Literacy share, 2001','lights_max2001':'Maximum night-time brightness, 2001',
 'vdp_pwr_h_dom_avg_11':'Domestic power supply (hours/day), 2011',
 'vdp_pwr_d_com_11':'Commercial electricity availability',
 'vd_pwr_d_all_11':'All-sector electricity availability'}

plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11,'axes.spines.top':False,
 'axes.spines.right':False,'figure.facecolor':'white','axes.facecolor':'white',
 'savefig.facecolor':'white','axes.titleweight':'bold','axes.titlesize':13,'axes.labelsize':11,'legend.frameon':False,'lines.linewidth':2,'savefig.dpi':250})
COLORS=['#0072B2','#D55E00','#009E73']
SHORT_NAMES={'vd_pwr_d_dom_11':'Domestic availability','hpca11_msl_elec':'Household lighting','work_p_11':'All work','work_f_11':'Female work','work_pooled_ot_p_11':'Other work','work_pooled_ot_f_11':'Female other work','vdp_pwr_d_com_11':'Commercial availability','vd_pwr_d_all_11':'All-sector availability'}
CAT=['Other villages','SC majority','ST majority']
figures=[]
def save(fig, stem, caption):
    width=fig.get_size_inches()[0]
    wrapped=textwrap.fill(caption,width=max(70,int(width*12)))
    lines=wrapped.count('\n')+1
    bottom=max(.11,(.16*lines+.22)/fig.get_size_inches()[1])
    for ax in fig.axes:
        ax.set_axisbelow(True)
        ax.grid(axis='x' if stem in ['08_primary_caste_heterogeneity','09_employment_heterogeneity','11_specification_sensitivity','12_baseline_balance','13_majority_group_rdd','14_state_sample_coverage','18_productive_electricity_heterogeneity'] else 'y',color='#DDE3E8',linewidth=.6,alpha=.75)
        ax.tick_params(colors='#344054',labelsize=10)
    fig.text(.03,.018,wrapped,ha='left',va='bottom',fontsize=8.5,color='#475467')
    fig.tight_layout(rect=[0,bottom,1,.98],w_pad=2.7,h_pad=2.5)
    for ext in ['png','svg']:
        fig.savefig(F/f'{stem}.{ext}',dpi=250,bbox_inches='tight')
    plt.close(fig)
    figures.append({'file':f'figures/{stem}.png','caption':caption})

def fit(y,h=100,sample='sample_preferred',cluster='block_id',heter=True,donut=0,cutoff=299.5,baseline=False,subgroup=None,state_slopes=False):
    z=d.loc[d[sample].eq(1)].copy()
    z['x']=z.tot_p-cutoff
    z=z.loc[(z.x.abs()<h)&(z.x.abs()>donut)]
    if subgroup is not None:
        z=z.loc[subgroup(z)]
    z['D']=(z.tot_p>=cutoff).astype(float)
    needed=[y,'x','D',cluster,'st_code']+(['sc10','st10'] if heter else [])
    baseline_var={'vd_pwr_d_dom_11':'vd_pwr_d_dom_01','hpca11_msl_elec':'hpca01_msl_elec'}.get(y)
    if baseline and baseline_var:
        needed.append(baseline_var)
    z=z.dropna(subset=needed)
    X=pd.DataFrame({'const':1.,'eligible':z.D,'running':z.x,'D_x':z.D*z.x},index=z.index)
    if heter:
        for caste in ['sc10','st10']:
            X[caste]=z[caste]
            X['D_'+caste]=z.D*z[caste]
            X['x_'+caste]=z.x*z[caste]
            X['D_x_'+caste]=z.D*z.x*z[caste]
    if baseline and baseline_var:
        X['baseline']=z[baseline_var]
    X=pd.concat([X,pd.get_dummies(z.st_code,prefix='state',drop_first=True,dtype=float)],axis=1).astype(float)
    if state_slopes:
        for col in [c for c in X if c.startswith('state_')]:
            for interaction in ['eligible','running','D_x']:
                X[col+'_'+interaction]=X[col]*X[interaction]
    if np.linalg.matrix_rank(X.to_numpy())<X.shape[1]:
        raise ValueError('Rank-deficient regression design')
    model=sm.WLS(z[y].astype(float),X,weights=1-z.x.abs()/h).fit(cov_type='cluster',
          cov_kwds={'groups':z[cluster],'use_correction':True,'df_correction':True},use_t=True)
    return model,z,X

def row(model,z,y,term,h,spec):
    ci=model.conf_int().loc[term]
    return {'outcome':y,'outcome_label':NAMES.get(y,y),'term':term,'bandwidth':h,'specification':spec,
     'estimate':float(model.params[term]),'se':float(model.bse[term]),'p_value':float(model.pvalues[term]),
     'ci_low':float(ci.iloc[0]),'ci_high':float(ci.iloc[1]),'n':len(z),
     'n_left':int(z.D.eq(0).sum()),'n_right':int(z.D.eq(1).sum()),
     'clusters':int(model.n_groups) if hasattr(model,'n_groups') else int(z.block_id.nunique())}

local=d.loc[d.sample_preferred.eq(1)&d.local_100.eq(1)].copy()
desc=[]
for group in ['All villages']+CAT:
    group_data=local if group=='All villages' else local.loc[local.caste_group.eq(group)]
    for y in ['tot_p','pct_sc_01','pct_st_01','hpca01_msl_elec','hpca11_msl_elec',
              'vd_pwr_d_dom_01','vd_pwr_d_dom_11']+SECONDARY:
        s=group_data[y].dropna()
        desc.append({'group':group,'variable':y,'label':NAMES.get(y,y),'n':len(s),
          'missing_n':int(group_data[y].isna().sum()),'mean':s.mean(),'sd':s.std(),
          'p25':np.percentile(s,25,method='averaged_inverted_cdf'),'median':np.percentile(s,50,method='averaged_inverted_cdf'),'p75':np.percentile(s,75,method='averaged_inverted_cdf')})
pd.DataFrame(desc).to_csv(T/'descriptive_statistics.csv',index=False)
coverage=local.groupby(['state','caste_group','eligible'],observed=True).agg(
    n=('pca01_id','size'),blocks=('block_id','nunique'),districts=('stdt','nunique')).reset_index()
coverage.to_csv(T/'sample_coverage.csv',index=False)
missing=d.loc[d.sample_preferred.eq(1)&d.local_200.eq(1)].isna().sum().rename('missing_n').rename_axis('variable').reset_index()
missing.to_csv(T/'missingness_local_200.csv',index=False)

results=[]; main_models={}
for y in PRIMARY+SECONDARY:
    for h in [50,100,150,200]:
        model,z,X=fit(y,h)
        for term in ['D_sc10','D_st10']:
            results.append(row(model,z,y,term,h,'main'))
        joint=model.f_test('D_sc10=0, D_st10=0')
        if h==100:
            main_models[y]=(model,z,X,float(joint.pvalue))
            # Save the full model rather than only interesting coefficients.
            out=pd.DataFrame({'term':model.params.index,'estimate':model.params.values,
                 'se':model.bse.values,'p_value':model.pvalues.values,
                 'ci_low':model.conf_int().iloc[:,0].values,'ci_high':model.conf_int().iloc[:,1].values})
            out.to_csv(T/f'full_model_{y}.csv',index=False)
            (P/'verification'/f'model_{y}.txt').write_text(model.summary().as_text(),encoding='utf-8')

res=pd.DataFrame(results)
res['p_holm']=np.nan
for family in [PRIMARY,SECONDARY]:
    selected=res.outcome.isin(family)&res.bandwidth.eq(100)
    res.loc[selected,'p_holm']=multipletests(res.loc[selected,'p_value'],method='holm')[1]
res.to_csv(T/'heterogeneity_results.csv',index=False)
pd.DataFrame([{'outcome':y,'joint_sc_st_p_value':v[3]} for y,v in main_models.items()]).to_csv(T/'joint_tests.csv',index=False)

sens=[]
for y in PRIMARY:
    for spec,kw in [('main',{}),('no_post_lights_filter',{'sample':'sample_no_post_filter'}),
                    ('district_cluster',{'cluster':'stdt'}),('donut_5',{'donut':5}),
                    ('baseline_adjusted',{'baseline':True}),('state_specific_rd',{'state_slopes':True})]:
        m,z,X=fit(y,100,**kw)
        for term in ['D_sc10','D_st10']:
            r=row(m,z,y,term,100,spec)
            r['clusters']=int(z[kw.get('cluster','block_id')].nunique())
            sens.append(r)
pd.DataFrame(sens).to_csv(T/'specification_sensitivity.csv',index=False)

balance=[]
for y in ['pct_sc_01','pct_st_01','hpca01_msl_elec','vd_pwr_d_dom_01','lit_p_01','lights_max2001']:
    m,z,X=fit(y,100,heter=False)
    balance.append(row(m,z,y,'eligible',100,'pre_policy_balance'))
bal=pd.DataFrame(balance); bal['p_holm']=multipletests(bal.p_value,method='holm')[1]
bal.to_csv(T/'baseline_balance.csv',index=False)

placebo=[]
for cutoff in [149.5,449.5]:
    for y in PRIMARY:
        m,z,X=fit(y,50,heter=False,cutoff=cutoff)
        r=row(m,z,y,'eligible',50,'placebo_cutoff');r['cutoff']=cutoff
        placebo.append(r)
pd.DataFrame(placebo).to_csv(T/'placebo_cutoffs.csv',index=False)

subgroups=[]
for y in PRIMARY:
    for category in CAT:
        zz=local.loc[local.caste_group.eq(category)].dropna(subset=[y,'block_id'])
        side=[zz.loc[zz.eligible.eq(s)] for s in [0,1]]
        if min(len(s) for s in side)<50 or min(s.block_id.nunique() for s in side)<20:
            subgroups.append({'outcome':y,'group':category,'status':'Insufficient observations/clusters','n':len(zz)})
            continue
        m,z,X=fit(y,100,heter=False,subgroup=lambda v,c=category:v.caste_group.eq(c))
        r=row(m,z,y,'eligible',100,'majority_group');r.update(group=category,status='Estimated')
        subgroups.append(r)
sg=pd.DataFrame(subgroups);sg.to_csv(T/'majority_group_rdd.csv',index=False)

# Pooled benchmark: conventional estimate AND robust bias-corrected inference.
robust=[]
for y in PRIMARY+PRODUCTIVE:
    z=d.loc[d.sample_preferred.eq(1)&d.local_200.eq(1)].dropna(subset=[y,'running','block_id','st_code']).copy()
    covs=pd.get_dummies(z.st_code,drop_first=True,dtype=float)
    for label,kw in [('mserd',{}),('fixed_100',{'h':100,'b':150})]:
        capture=io.StringIO()
        with contextlib.redirect_stdout(capture):
            rr=rdrobust(y=z[y].to_numpy(),x=z.running.to_numpy(),c=0,
               covs=covs.to_numpy(),p=1,q=2,kernel='tri',vce='cr1',cluster=z.block_id.to_numpy(),
               masspoints='adjust',**kw)
        robust.append({'outcome':y,'method':label,'tau_conventional':float(rr.coef.iloc[0,0]),
             'tau_bias_corrected':float(rr.coef.iloc[2,0]),'se_robust':float(rr.se.iloc[2,0]),
             'p_robust':float(rr.pv.iloc[2,0]),'ci_low_robust':float(rr.ci.iloc[2,0]),
             'ci_high_robust':float(rr.ci.iloc[2,1]),'h_left':float(rr.bws.iloc[0,0]),
             'h_right':float(rr.bws.iloc[0,1]),'b_left':float(rr.bws.iloc[1,0]),
             'b_right':float(rr.bws.iloc[1,1]),'n_left':int(rr.N_h[0]),'n_right':int(rr.N_h[1]),
             'clusters':int(z.loc[((z.running<0)&(z.running.abs()<float(rr.bws.iloc[0,0])))|((z.running>=0)&(z.running.abs()<float(rr.bws.iloc[0,1]))),'block_id'].nunique()),
             'clusters_input':int(z.block_id.nunique()),
             'clusters_bias':int(z.loc[((z.running<0)&(z.running.abs()<float(rr.bws.iloc[1,0])))|((z.running>=0)&(z.running.abs()<float(rr.bws.iloc[1,1]))),'block_id'].nunique()),
             'clusters_package':int(rr.n_clust)})
        (P/'verification'/f'rdrobust_{y}_{label}.txt').write_text(str(rr)+'\n'+capture.getvalue(),encoding='utf-8')
rb=pd.DataFrame(robust);rb.to_csv(T/'pooled_rdrobust.csv',index=False)

pretrends=[]
for yr in range(1998,2005):
    y=f'lights_max{yr}';m,z,X=fit(y,100,heter=False)
    pretrends.append(row(m,z,y,'eligible',100,'pre_policy_nightlights'))
pd.DataFrame(pretrends).to_csv(T/'pre_policy_nightlights.csv',index=False)

# Independently check every main weighted regression and cluster covariance.
matrix_checks=[]
for outcome,(m,z,X,_) in main_models.items():
    xx=X.to_numpy();yy=z[outcome].to_numpy();w=1-z.x.abs().to_numpy()/100
    bread=np.linalg.inv(xx.T@(w[:,None]*xx));beta=bread@(xx.T@(w*yy))
    scores=xx*(w*(yy-xx@beta))[:,None]
    group_scores=pd.DataFrame(scores).groupby(z.block_id.to_numpy()).sum().to_numpy()
    g=len(group_scores);n,k=xx.shape
    cov=bread@(group_scores.T@group_scores)@bread*(g/(g-1))*((n-1)/(n-k))
    bd=float(np.max(np.abs(beta-m.params.to_numpy())))
    cd=float(np.max(np.abs(cov-m.cov_params().to_numpy())))
    assert bd<1e-8 and cd<1e-7, outcome
    matrix_checks.append({'outcome':outcome,'coefficient_max_difference':bd,'covariance_max_difference':cd})
(P/'verification/independent_matrix_checks.json').write_text(json.dumps(matrix_checks,indent=2))
verification={'python_executed':True,'stata_executed':False,'unique_village_ids':bool(d.pca01_id.is_unique),
 'independent_cr1_check_passed':True,'coefficient_max_abs_difference':max(r['coefficient_max_difference'] for r in matrix_checks),
 'covariance_max_abs_difference':max(r['covariance_max_difference'] for r in matrix_checks),
 'main_models_independently_checked':len(matrix_checks),
 'source_n':json.loads((P/'docs/source_manifest.json').read_text())['source_n'],
 'local_main_n':len(local),'local_main_blocks':int(local.block_id.nunique()),
 'local_main_districts':int(local.stdt.nunique()),'main_bandwidth':100,
 'primary_tests':4,'exploratory_secondary_tests':12}
(P/'verification/execution_status.json').write_text(json.dumps(verification,indent=2))

source_caption='Source: Burlig-Preonas public replication data; 2001/2011 Census. Local sample: population 200-399.'
fig,ax=plt.subplots(figsize=(9,4))
counts=d.loc[d.sample_preferred.eq(1)&d.local_200.eq(1)].groupby('tot_p').size()
ax.bar(counts.index,counts.values,width=1,color=COLORS[0],alpha=.8)
ax.axvline(299.5,color=COLORS[1],ls='--',label='Eligibility boundary (>=300)')
ax.set(xlabel='2001 Census population (persons)',ylabel='Number of villages',title='Population frequencies around the eligibility threshold')
ax.legend();save(fig,'01_population_frequencies','Source: public RGGVY archive; 2001 Census, population 100-499. Integer counts; this is not a continuous density test.')

fig,axes=plt.subplots(1,2,figsize=(10,4))
for ax,caste,label in zip(axes,['pct_sc_01','pct_st_01'],['Scheduled Caste','Scheduled Tribe']):
    ax.hist(local[caste].dropna()*100,bins=np.arange(0,105,5),color=COLORS[0],edgecolor='white')
    ax.set(title=f'{label} population share',xlabel='2001 population share (%)',ylabel='Number of villages')
save(fig,'02_baseline_caste_distributions',source_caption+' Caste shares are measured before the policy.')

def rd_panel(ax,y,title=None,scale=100,frame=None):
    z=d.loc[d.sample_preferred.eq(1)&d.local_200.eq(1)].copy() if frame is None else frame.copy()
    z=z.dropna(subset=[y,'running']);z['bin']=np.floor(z.running/20)*20+10
    bins=z.groupby(['eligible','bin']).agg(mean=(y,'mean'),count=(y,'count'),population=('tot_p','mean')).reset_index()
    for side,color,label in [(0,COLORS[0],'Below 300'),(1,COLORS[1],'300 or more')]:
        q=bins.loc[bins.eligible.eq(side)]
        ax.scatter(q.population,q['mean']*scale,s=45,edgecolors='white',linewidths=.8,label=label,color=color,zorder=3)
        q=z.loc[z.eligible.eq(side)&z.running.abs().lt(100)]
        if len(q)>5:
            model=sm.WLS(q[y],sm.add_constant(q.running),weights=1-q.running.abs()/100).fit()
            grid=np.linspace(-99.5 if side==0 else 0,0 if side==0 else 99.5,100)
            ax.plot(grid+299.5,model.predict(sm.add_constant(grid))*scale,color=color,zorder=2)
    ax.axvspan(199.5,399.5,color='#98A2B3',alpha=.08,zorder=0)
    ax.axvline(299.5,color='#667085',ls='--',lw=1.2)
    ax.text(299.5,.98,'  Eligibility cutoff',transform=ax.get_xaxis_transform(),ha='left',va='top',fontsize=9,color='#475467')
    ax.set(title=title or SHORT_NAMES.get(y,NAMES.get(y,y)),xlabel='Village population, 2001 (persons)',ylabel='Percent' if scale==100 else 'Brightness units (0-63)',xlim=(99.5,499.5),xticks=[100,200,300,400,500])
    ax.legend(fontsize=9,loc='best')

fig,axes=plt.subplots(1,2,figsize=(11,4))
rd_panel(axes[0],'pct_sc_01');rd_panel(axes[1],'pct_st_01')
save(fig,'03_caste_composition_balance','Source: public RGGVY archive, 2001 Census. Dots: 20-person bins at mean population; lines: unadjusted triangular local-linear fits, h=100.')
for idx,y in [(4,'vd_pwr_d_dom_11'),(5,'hpca11_msl_elec'),(6,'hpca01_msl_elec')]:
    fig,ax=plt.subplots(figsize=(9,4));rd_panel(ax,y)
    save(fig,f'{idx:02d}_rd_{y}','Source: public RGGVY archive, Census 2001/2011. Dots: 20-person bins at mean population; lines: unadjusted local-linear fits, h=100. Formal models include state effects. Shading: h=100; display lines extended to the cutoff.')

fig,axes=plt.subplots(1,2,figsize=(11,4))
for ax,y,base in zip(axes,PRIMARY,['vd_pwr_d_dom_01','hpca01_msl_elec']):
    vals=local.groupby('caste_group')[[base,y]].mean().reindex(CAT)*100
    x=np.arange(3);ax.bar(x-.18,vals[base],.36,label='2001',color=COLORS[0]);ax.bar(x+.18,vals[y],.36,label='2011',color=COLORS[1])
    ax.set(xticks=x,xticklabels=['Other','SC majority','ST majority'],ylabel='Percent',title=NAMES[y]);ax.legend()
save(fig,'07_access_and_adoption_by_group',source_caption+' Group means are descriptive, not causal effects.')

def forest(ax,frame,title,xlabel='Effect difference (pp per +10 pp baseline caste share)'):
    frame=frame.reset_index(drop=True)
    lo=min(0,float(frame.ci_low.min()*100));hi=max(0,float(frame.ci_high.max()*100));span=max(hi-lo,.5)
    for i,r in frame.iterrows():
        color=COLORS[0] if r.term=='D_sc10' else COLORS[1]
        if i%2==0: ax.axhspan(i-.45,i+.45,color='#F2F4F7',zorder=0)
        ax.errorbar(r.estimate*100,i,xerr=np.array([[r.estimate-r.ci_low],[r.ci_high-r.estimate]])*100,fmt='o' if r.term=='D_sc10' else 's',color=color,capsize=4,markersize=7,zorder=3)
        ax.text(hi+.07*span,i,f'{r.estimate*100:+.2f}  [{r.ci_low*100:+.2f}, {r.ci_high*100:+.2f}]',va='center',fontsize=9,color='#344054')
    ax.axvline(0,color='#667085',ls='--',linewidth=1.2)
    ax.set(yticks=range(len(frame)),yticklabels=[SHORT_NAMES.get(r.outcome,r.outcome)+(' / SC' if r.term=='D_sc10' else ' / ST') for _,r in frame.iterrows()],xlabel=xlabel,title=title,xlim=(lo-.1*span,hi+.68*span))
    ax.invert_yaxis()

fig,ax=plt.subplots(figsize=(12,4.8));forest(ax,res.loc[res.outcome.isin(PRIMARY)&res.bandwidth.eq(100)],'Does caste composition change the eligibility effect?')
save(fig,'08_primary_caste_heterogeneity','Source: executed local-linear RDD, h=100, state effects and block-clustered 95% t intervals. Conventional intervals; exploratory heterogeneity.')
fig,ax=plt.subplots(figsize=(12,6));forest(ax,res.loc[res.outcome.isin(EMPLOYMENT)&res.bandwidth.eq(100)],'Employment heterogeneity: exploratory outcomes')
save(fig,'09_employment_heterogeneity','Source: executed local-linear RDD, Census 2011; h=100, state effects, block-clustered 95% t intervals. See Holm-adjusted p-values in tables.')

fig,axes=plt.subplots(2,2,figsize=(11,7))
for row_i,y in enumerate(PRIMARY):
    for col_i,term in enumerate(['D_sc10','D_st10']):
        ax=axes[row_i,col_i];q=res.loc[res.outcome.eq(y)&res.term.eq(term)].sort_values('bandwidth')
        ax.errorbar(q.bandwidth,q.estimate*100,yerr=np.vstack([(q.estimate-q.ci_low)*100,(q.ci_high-q.estimate)*100]),fmt='o-',capsize=3,color=COLORS[col_i])
        ax.axhline(0,color='#777777',ls='--');ax.set(title=SHORT_NAMES[y]+(' / SC' if col_i==0 else ' / ST'),xlabel='Bandwidth each side (persons)',ylabel='Effect difference (pp per +10 pp share)',xticks=[50,100,150,200])
save(fig,'10_bandwidth_sensitivity','Source: executed caste-interacted local-linear RDD; 95% block-clustered t intervals. Wider bandwidths change both precision and smoothing bias.')

fig,axes=plt.subplots(2,2,figsize=(13,8.5))
sensdf=pd.DataFrame(sens)
for row_i,y in enumerate(PRIMARY):
    for col_i,term in enumerate(['D_sc10','D_st10']):
        ax=axes[row_i,col_i];q=sensdf.loc[sensdf.outcome.eq(y)&sensdf.term.eq(term)].reset_index(drop=True)
        ax.errorbar(q.estimate*100,np.arange(len(q)),xerr=np.vstack([(q.estimate-q.ci_low)*100,(q.ci_high-q.estimate)*100]),fmt='o',capsize=3,color=COLORS[col_i])
        ax.axvline(0,color='#777777',ls='--');ax.set(yticks=range(len(q)),yticklabels=q.specification.map({'main':'Main model','no_post_lights_filter':'No post-policy light filter','district_cluster':'District clustering','donut_5':'Exclude ±5 persons','baseline_adjusted':'Baseline adjustment','state_specific_rd':'State-specific RD'}),xlabel='Effect difference (pp per +10 pp share)',title=SHORT_NAMES[y]+(' / SC' if col_i==0 else ' / ST'));ax.invert_yaxis()
save(fig,'11_specification_sensitivity','Source: executed RDD, h=100; 95% t intervals. Includes state-specific discontinuities and population slopes; see table for all specifications.')

fig,ax=plt.subplots(figsize=(10,5))
for i,r in bal.iterrows():
    scale=1 if r.outcome=='lights_max2001' else 100
    ax.errorbar(r.estimate*scale,i,xerr=np.array([[r.estimate-r.ci_low],[r.ci_high-r.estimate]])*scale,fmt='o',color=COLORS[0],capsize=3)
ax.axvline(0,color='#777777',ls='--');ax.set(yticks=range(len(bal)),yticklabels=[NAMES.get(x,x) for x in bal.outcome],xlabel='Eligibility-boundary difference (pp; brightness in its native units)',title='Pre-policy balance checks');ax.invert_yaxis()
save(fig,'12_baseline_balance','Source: executed local-linear RDD at 299.5, h=100, state effects, block-clustered 95% t intervals. A small p-value can signal a design concern.')

fig,axes=plt.subplots(1,2,figsize=(11,4))
for ax,y in zip(axes,PRIMARY):
    q=sg.loc[sg.outcome.eq(y)&sg.status.eq('Estimated')].reset_index(drop=True)
    for i,r in q.iterrows():
        ax.errorbar(r.estimate*100,i,xerr=np.array([[r.estimate-r.ci_low],[r.ci_high-r.estimate]])*100,fmt='o',color=COLORS[i%3],capsize=3)
    ax.axvline(0,color='#777777',ls='--');ax.set(yticks=range(len(q)),yticklabels=q['group'],xlabel='Eligibility effect (percentage points)',title=NAMES[y]);ax.invert_yaxis()
save(fig,'13_majority_group_rdd','Source: subgroup local-linear RDD, h=100; state effects and block-clustered 95% t intervals. >=50 observations and >=20 blocks per side required.')

fig,ax=plt.subplots(figsize=(9,5));state_counts=local.groupby('state').size().sort_values();ax.barh([x.title() for x in state_counts.index],state_counts.values,color=COLORS[0]);ax.bar_label(ax.containers[0],padding=5,fontsize=9);ax.set_xlim(0,state_counts.max()*1.2);ax.set(title='State coverage of the local estimation sample',xlabel='Number of villages',ylabel='State')
save(fig,'14_state_sample_coverage',source_caption+' Pooled estimates use available valid states; these counts do not establish state-specific statistical power.')

fig,ax=plt.subplots(figsize=(9,4));pp=pd.DataFrame(pretrends)
ax.errorbar(range(1998,2005),pp.estimate,yerr=np.vstack([pp.estimate-pp.ci_low,pp.ci_high-pp.estimate]),fmt='o-',color=COLORS[0],capsize=3)
ax.axhline(0,color='#777777',ls='--');ax.set(title='Night-light discontinuities before RGGVY',xlabel='Year (pre-policy)',ylabel='Brightness difference (0-63 scale)',xticks=range(1998,2005))
save(fig,'15_pre_policy_nightlight_checks','Source: public RGGVY archive, DMSP annual maximum brightness 1998-2004. Separate state-adjusted local-linear RDDs, h=100; block-clustered 95% t intervals.')

fig,ax=plt.subplots(figsize=(9,4));gap=local.groupby('caste_group').access_adoption_gap.mean().reindex(CAT)*100
ax.bar(['Other villages','SC majority','ST majority'],gap,color=COLORS);ax.set(title='Village availability and household adoption are different margins',xlabel='Village composition in 2001',ylabel='Mean availability minus lighting share (pp)')
save(fig,'16_access_adoption_gap',source_caption+' Descriptive difference between two village-level measures; not a disconnection rate or individual caste gap.')

fig,axes=plt.subplots(1,2,figsize=(11,4))
for ax,y in zip(axes,PRODUCTIVE):
    rd_panel(ax,y)
save(fig,'17_productive_electricity_rdd','Source: public RGGVY archive, Census 2011. Commercial and all-sector margins added as exploratory literature-motivated checks; unadjusted display fits, h=100.')
fig,ax=plt.subplots(figsize=(12,4.8));forest(ax,res.loc[res.outcome.isin(PRODUCTIVE)&res.bandwidth.eq(100)],'Productive electricity: exploratory caste heterogeneity')
save(fig,'18_productive_electricity_heterogeneity','Source: executed local-linear RDD, h=100, state effects and block-clustered 95% t intervals. Exploratory outcomes added after the primary benchmark was examined.')

integer=local.groupby(['tot_p','eligible']).size().rename('n').reset_index()
integer.to_csv(T/'integer_population_counts.csv',index=False)
(P/'docs/figure_manifest.json').write_text(json.dumps(figures,indent=2))
summary={'primary':res.loc[res.outcome.isin(PRIMARY)&res.bandwidth.eq(100)].to_dict('records'),
 'secondary':res.loc[res.outcome.isin(SECONDARY)&res.bandwidth.eq(100)].to_dict('records'),
 'pooled':rb.to_dict('records'),'balance':bal.to_dict('records'),
 'subgroups':sg.to_dict('records'),'sample':verification,
 'group_counts':local.groupby(['caste_group','eligible']).size().reset_index(name='n').to_dict('records')}
(P/'verification/results_summary.json').write_text(json.dumps(summary,indent=2))
print(res.loc[res.outcome.isin(PRIMARY)&res.bandwidth.eq(100)].to_string(index=False),flush=True)
print(rb.to_string(index=False),flush=True)
print('Executed analysis and 18 figures saved; independent clustered covariance check passed.',flush=True)
