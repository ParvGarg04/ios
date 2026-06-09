import React, { useEffect, useState } from 'react';
import { fetchDashboardStats, fetchPendingReviews, fetchAllMembers } from '../hooks/useFirestore';
import { DashboardStats, ReviewItem } from '../types';

export default function DashboardPage() {
  const [stats,    setStats]   = useState<DashboardStats | null>(null);
  const [recents,  setRecents] = useState<ReviewItem[]>([]);
  const [loading,  setLoading] = useState(true);
  const [error,    setError]   = useState('');

  useEffect(() => {
    load();
  }, []);

  async function load() {
    setLoading(true);
    setError('');
    try {
      const members  = await fetchAllMembers();
      const userMap  = Object.fromEntries(members.map(m => [m.id, m.name]));
      const [s, r]   = await Promise.all([
        fetchDashboardStats(),
        fetchPendingReviews(userMap),
      ]);
      setStats(s);
      setRecents(r.slice(0, 5));
    } catch (e: any) {
      setError('Failed to load dashboard. ' + e.message);
    } finally {
      setLoading(false);
    }
  }

  const fmtDate = (d: Date) => {
    const now   = new Date();
    const diff  = (now.getTime() - d.getTime()) / 1000;
    if (diff < 60)   return 'Just now';
    if (diff < 3600) return `${Math.floor(diff/60)}m ago`;
    if (diff < 86400)return `${Math.floor(diff/3600)}h ago`;
    return d.toLocaleDateString();
  };

  if (loading) return <LoadingState />;

  return (
    <div>
      <div className="page-header">
        <div>
          <div className="page-title">Dashboard</div>
          <div className="page-subtitle">Welcome back — here's what's happening today.</div>
        </div>
        <button className="btn btn-outline" onClick={load} style={{ gap:6 }}>
          ↻ Refresh
        </button>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      {/* Stats */}
      <div className="stats-grid">
        <StatCard icon="👥" iconClass="blue"   value={stats?.totalMembers ?? 0}        label="Total Members"         />
        <StatCard icon="⏳" iconClass="yellow" value={stats?.pendingReviews ?? 0}      label="Pending Reviews"       />
        <StatCard icon="📈" iconClass="green"  value={`${stats?.todayCompletionRate ?? 0}%`} label="Weekly Rate"  />
        <StatCard icon="💧" iconClass="blue"   value={stats?.todayWaterLogs ?? 0}      label="Hydration Logs Today"  />
        <StatCard icon="✅" iconClass="green"  value={stats?.weeklyTasksCompleted ?? 0} label="Tasks Verified (7d)" />
        <StatCard icon="❌" iconClass="red"    value={stats?.weeklyTasksMissed ?? 0}    label="Tasks Rejected (7d)" />
      </div>

      {/* Completion bar */}
      <div className="card" style={{ marginBottom:24 }}>
        <div className="card-header">Weekly Completion Rate</div>
        <div className="card-body">
          <div style={{ display:'flex', alignItems:'center', gap:14 }}>
            <div style={{ flex:1 }} className="progress-bar">
              <div className="progress-bar-fill" style={{ width:`${stats?.todayCompletionRate ?? 0}%` }} />
            </div>
            <span style={{ fontWeight:700, fontSize:'1rem', minWidth:42, textAlign:'right' }}>
              {stats?.todayCompletionRate ?? 0}%
            </span>
          </div>
          <div style={{ marginTop:10, fontSize:'0.78rem', color:'var(--text-secondary)' }}>
            {stats?.weeklyTasksCompleted} verified out of{' '}
            {(stats?.weeklyTasksCompleted ?? 0) + (stats?.weeklyTasksMissed ?? 0)} submissions this week
          </div>
        </div>
      </div>

      {/* Recent pending */}
      <div className="card">
        <div className="card-header">
          Recent Pending Reviews
          <a href="/reviews" className="btn btn-ghost btn-sm">View all →</a>
        </div>
        {recents.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">🎉</div>
            <div className="empty-state-title">All caught up!</div>
            <div className="empty-state-message">No pending reviews right now.</div>
          </div>
        ) : (
          <div className="table-wrapper">
            <table className="table">
              <thead>
                <tr>
                  <th>Type</th>
                  <th>Title</th>
                  <th>Member</th>
                  <th>Submitted</th>
                  <th>Attachment</th>
                </tr>
              </thead>
              <tbody>
                {recents.map(item => (
                  <tr key={item.id}>
                    <td>
                      <span className={`badge ${item.kind === 'water' ? 'badge-active' : 'badge-normal'}`}>
                        {item.kind === 'water' ? '💧 Hydration' : '📋 Task'}
                      </span>
                    </td>
                    <td style={{ fontWeight:500 }}>{item.title}</td>
                    <td>
                      <div style={{ display:'flex', alignItems:'center', gap:8 }}>
                        <div className="member-avatar">{(item.userName ?? '?')[0].toUpperCase()}</div>
                        {item.userName ?? item.userId.slice(0,8)}
                      </div>
                    </td>
                    <td style={{ color:'var(--text-secondary)', fontSize:'0.8rem' }}>
                      {fmtDate(item.submittedAt)}
                    </td>
                    <td>{item.imageURL ? '📎 Yes' : <span style={{color:'var(--text-muted)'}}>—</span>}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

function StatCard({ icon, iconClass, value, label }: { icon:string; iconClass:string; value:number|string; label:string }) {
  return (
    <div className="stat-card">
      <div className={`stat-icon ${iconClass}`}>{icon}</div>
      <div>
        <div className="stat-value">{value}</div>
        <div className="stat-label">{label}</div>
      </div>
    </div>
  );
}

function LoadingState() {
  return (
    <div>
      <div className="page-header">
        <div className="page-title">Dashboard</div>
      </div>
      <div className="stats-grid">
        {Array.from({length:6}).map((_,i) => (
          <div key={i} className="stat-card" style={{ background:'var(--border)', opacity:0.4, minHeight:100 }} />
        ))}
      </div>
      <div style={{ textAlign:'center', padding:40, color:'var(--text-secondary)' }}>
        <div className="spinner" style={{margin:'0 auto 12px'}} />
        Loading dashboard…
      </div>
    </div>
  );
}
