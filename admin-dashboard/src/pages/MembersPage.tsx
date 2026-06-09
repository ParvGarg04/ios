import React, { useEffect, useState, useCallback } from 'react';
import { fetchAllMembers, fetchAllSubmissions, fetchAllWaterLogs } from '../hooks/useFirestore';
import { UserProfile, TaskSubmission, WaterLog } from '../types';

interface MemberStat {
  member: UserProfile;
  totalSubmissions: number;
  verifiedCount: number;
  rejectedCount: number;
  pendingCount: number;
  waterLogs: number;
  completionRate: number;
}

export default function MembersPage() {
  const [stats,   setStats]   = useState<MemberStat[]>([]);
  const [loading, setLoading] = useState(true);
  const [error,   setError]   = useState('');
  const [search,  setSearch]  = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [members, subs, logs] = await Promise.all([
        fetchAllMembers(),
        fetchAllSubmissions(),
        fetchAllWaterLogs(),
      ]);

      const memberStats: MemberStat[] = members.map(m => {
        const mSubs  = subs.filter(s => s.userId === m.id);
        const mLogs  = logs.filter(l => l.userId === m.id);
        const ver    = mSubs.filter(s => s.verificationStatus === 'verified').length;
        const rej    = mSubs.filter(s => s.verificationStatus === 'rejected').length;
        const pend   = mSubs.filter(s => s.verificationStatus === 'pending_review').length;
        const rate   = mSubs.length > 0 ? Math.round((ver / mSubs.length) * 100) : 0;
        return {
          member:            m,
          totalSubmissions:  mSubs.length,
          verifiedCount:     ver,
          rejectedCount:     rej,
          pendingCount:      pend,
          waterLogs:         mLogs.length,
          completionRate:    rate,
        };
      });

      setStats(memberStats.sort((a, b) => b.totalSubmissions - a.totalSubmissions));
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const filtered = stats.filter(s =>
    s.member.name.toLowerCase().includes(search.toLowerCase()) ||
    s.member.email.toLowerCase().includes(search.toLowerCase())
  );

  const initials = (name: string) =>
    name.split(' ').map(p => p[0]).join('').slice(0,2).toUpperCase();

  return (
    <div>
      <div className="page-header">
        <div>
          <div className="page-title">Members</div>
          <div className="page-subtitle">Overview of all registered members and their progress</div>
        </div>
        <button className="btn btn-outline" onClick={load}>↻ Refresh</button>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      <div className="filter-bar">
        <input className="search-input" placeholder="Search members…"
          value={search} onChange={e => setSearch(e.target.value)} />
        <span style={{ marginLeft:'auto', fontSize:'0.8rem', color:'var(--text-secondary)' }}>
          {filtered.length} member{filtered.length !== 1 ? 's' : ''}
        </span>
      </div>

      {loading ? (
        <div style={{ textAlign:'center', padding:60 }}>
          <div className="spinner" style={{ margin:'0 auto 12px' }} />
        </div>
      ) : filtered.length === 0 ? (
        <div className="empty-state card">
          <div className="empty-state-icon">👥</div>
          <div className="empty-state-title">No members found</div>
          <div className="empty-state-message">Members who sign up will appear here.</div>
        </div>
      ) : (
        <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill, minmax(320px, 1fr))', gap:16 }}>
          {filtered.map(s => (
            <MemberCard key={s.member.id} stat={s} initials={initials} />
          ))}
        </div>
      )}
    </div>
  );
}

function MemberCard({ stat, initials }: { stat: MemberStat; initials: (n:string) => string }) {
  const { member, totalSubmissions, verifiedCount, rejectedCount, pendingCount, waterLogs, completionRate } = stat;

  return (
    <div className="card">
      <div className="card-body">
        {/* Header */}
        <div style={{ display:'flex', alignItems:'center', gap:14, marginBottom:16 }}>
          <div className="member-avatar" style={{ width:46, height:46, fontSize:'1rem' }}>
            {initials(member.name)}
          </div>
          <div>
            <div style={{ fontWeight:600, fontSize:'0.95rem' }}>{member.name}</div>
            <div style={{ fontSize:'0.78rem', color:'var(--text-secondary)' }}>{member.email}</div>
          </div>
          <div style={{ marginLeft:'auto' }}>
            <span className="badge badge-active">🔥 {member.streak}d</span>
          </div>
        </div>

        {/* Completion bar */}
        <div style={{ marginBottom:16 }}>
          <div style={{ display:'flex', justifyContent:'space-between', marginBottom:5, fontSize:'0.78rem', color:'var(--text-secondary)' }}>
            <span>Completion Rate</span>
            <span style={{ fontWeight:600, color:'var(--text)' }}>{completionRate}%</span>
          </div>
          <div style={{ background:'var(--border)', borderRadius:999, height:7, overflow:'hidden' }}>
            <div style={{
              height:'100%',
              width:`${completionRate}%`,
              background: completionRate >= 70 ? 'var(--success)' : completionRate >= 40 ? 'var(--warning)' : 'var(--danger)',
              borderRadius:999,
              transition:'width 0.5s ease',
            }} />
          </div>
        </div>

        {/* Stats row */}
        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr 1fr 1fr', gap:8, textAlign:'center' }}>
          {[
            { label:'Total', value: totalSubmissions, color:'var(--text)' },
            { label:'Verified', value: verifiedCount, color:'var(--success)' },
            { label:'Rejected', value: rejectedCount, color:'var(--danger)' },
            { label:'Water 💧', value: waterLogs, color:'var(--accent)' },
          ].map(item => (
            <div key={item.label} style={{
              background:'var(--bg)', borderRadius:8, padding:'8px 4px',
            }}>
              <div style={{ fontWeight:700, fontSize:'1rem', color: item.color }}>{item.value}</div>
              <div style={{ fontSize:'0.68rem', color:'var(--text-secondary)', marginTop:2 }}>{item.label}</div>
            </div>
          ))}
        </div>

        {/* Pending badge if any */}
        {pendingCount > 0 && (
          <div style={{ marginTop:12 }}>
            <span className="badge badge-pending">⏳ {pendingCount} pending review{pendingCount !== 1 ? 's' : ''}</span>
          </div>
        )}
      </div>
    </div>
  );
}
