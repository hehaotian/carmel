#!/usr/bin/env python2.7
"""
compute sblm score on nbest output

verify stdout from
 xrs_info_decoder --nbest-output - --sbmt.sblm.level=verbose --sbmt.sblm.file - --sbmt.ngram.file -

or just compare (or add) score if no component_score logs are kept
"""

import sys
import re
import tree
from graehl import *
from dumpx import *
from ngram import *
from pcfg import *
from tree import *
from nbest import *

sbpre='sb'
pcpre='spc'

def checkunks(xs):
    for n in xs:
        e=needsesc(n)
        if e is not None:
            warn("reserved char %s in feature name %s"%(e,n),max=1)


unks=set([])
def tounk(x):
    return '<unk>' if x.startswith('GLUE') or x in unks else x

def pcfg_score(tree,lm,term=True,num2at=True):
    def score1lvl(t):
        p=t.label
        sent=[sblm_ngram.start]+[x.label for x in t.children]+[sblm_ngram.end,None]
        i=len(sent)-1
        s=0
        while i>1:
            sent[i]=sent[i-1]
            sent[i-1]=p
            sw=lm.score_word_combined(sent,i)
            #warn('score1w','%s = %s'%(' '.join(sent[max(0,i-4):i+1]),sw),max=100)
            s+=sw
            i-=1
        #warn('score1','%s %s %s'%(p,' '.join(sent),s),max=10)
        return s
    def score(t):
        if t.is_terminal() or (not term and t.is_preterminal()):
            return 0
        s=score1lvl(t)
        for c in t.children:
            s+=score(c)
        return s
    #warn('score',str(tree),max=1)
    return -score(tree)

def sblmunk(tree,lm,word=False,cat=False):
    def r(l,cv):
        if len(cv):
            if cat and lm.is_unk(l): return sum(cv)+1
        else:
            #'"'+l+'"'
            if word and lm.is_unk(l): return 1
        return sum(cv)
    return tree.reduce(r)

def check_nbest(l,lm,term=True,strip=True,flatten=True,num2at=True,output_nbest=None,maxwords=999999,lineno='?'):
    l=l.rstrip()
    tstr=getfield_brace('tree',l)
    t=nbest_tree(tstr) #str_to_tree_warn(tstr)
    if t is None:
        warn("no tree"," from %s line #%s"%(tstr,lineno))
        return False
    if len(t)>maxwords:
        return False
    rt=t.str_impl(lrb=False)
    if tstr!=rt:
        s=' => '.join(smallest_difference([tstr,rt],porch=2))
        warn('mismatch tree roundtrip (should just be -LRB- and -RRB- terminals',' diff = %s \norig = %s\nroundtrip = %s'%(s,tstr,rt),max=2)
    def label(x):
        return tounk(sbmt_lhs_label(x,num2at))
    t=t.mapnode(label)

    def skiplabel(y):
        if strip:
            y=strip_subcat(y)
        return no_bar(y) if flatten else y
    t=t.map_skipping(skiplabel)

    fv=getfields_num(l)
    sb=inds(fv,sbpre)
    pc=inds(fv,pcpre)
    fvd=dict(fv)
    checkunks(fvd.iterkeys())

    line=[l,'']
    def replfeat(f,v2,suf1='(nbest)',suf2='(python)'):
        if f in fvd:
            v=fvd[f]
            if v is None or v2 is None:
                raise Exception("replfeat %s %s %s"%(f,v,v2))
            equal_or_warn(v,v2,f,suf1,suf2)
            line[0]=stripnumfeat(f,line[0])
        line[1]+=' %s=%s'%(f,v2)

    replfeat('sblm-nts',t.size_nts())
    if lm is not None:
        replfeat('sblm',pcfg_score(t,lm,term,num2at))
        replfeat('sblm-unkword',sblmunk(t,lm,word=True))
        replfeat('sblm-unkcat',sblmunk(t,lm,cat=True))

    sent=fvd['sent']
    sbt=IntDict()
    pct=IntDict()
    def vpc(p,c):
        pct[(p,c)]+=1
    def vlr(left,right):
        sbt[(left,no_none(right,'</s>'))]+=1
    t.visit_pcl(vpc,leaf=False,root=False)
    t.visit_lrl(vlr,leaf=False,left='<s>',right='</s>')
    head='sent=%s tree=%s\ntree-orig=%s'%(sent,t,tstr)
    if len(sb):
        warn_diff(sb,sbt,desc=sbpre,header=head)
    if len(pc):
        warn_diff(pc,pct,desc=pcpre,header=head)
    if output_nbest is not None:
        s=stripinds('%s|%s'%(sbpre,pcpre),line[0])
        output_nbest.write('%s %s %s%s\n'%(s,strinds(sbpre,sbt),strinds(pcpre,pct),line[1]))
    return True

@optfunc.arghelp('lm','SRI ngram trained by pcfg.py')
@optfunc.arghelp('nbest','sbmt_decoder nbest list (optionally with sblm score debugging logs before each nbest)')
def nbest_sblm_main(lm='nbest.pcfg.srilm',
                    nbest='nbest.txt',
                    strip=True,
                    flatten=True,
                    num2at=True,
                    term=True,
                    output_nbest='',
                    maxwords=999999,
                    logp_unk=0.0,
                    closed=True
                    ):
    lm=None if lm=='' else ngram(lm=lm,closed=closed)
    lm.set_logp_unk(logp_unk)
    output_nbest=None if output_nbest=='' else open(output_nbest,'w')
    n=0
    ng=0
    for l in open(nbest):
        if l.startswith("NBEST sent="):
            n+=1
            if check_nbest(l,lm,term,strip,flatten,num2at,output_nbest,maxwords,lineno=n):
                ng+=1
    info_summary()
    log("%s good out of %s NBEST lines"%(ng,n))

import optfunc
optfunc.main(nbest_sblm_main)
