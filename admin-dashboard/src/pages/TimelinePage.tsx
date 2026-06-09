import React, { useEffect, useState, useCallback } from 'react';
import { fetchAllMembers, fetchAllSubmissions, fetchAllWaterLogs } from '../hooks/useFirestore';
import { TaskSubmission, WaterLog, UserProfile } from '../types';

interface TimelineEntry {
  id:       string;
  kind:     'task' | 'water';
  title:    string;
  userId:   string;
  userName: string;
  date:     Date;
  status:   string;
  imageURL?: string;
  note?:    string;
  comment?: string;
}

export default function TimelinePage() {
  const [entries,  setEntries]  = useState<TimelineEntry[]>([]);
  const [filtered, setFiltered] = useState<TimelineEntry[]>([]);
  const [members,  setMembers]  = useState<UserProfile[]>([]);
  const [loading,  setLoading]  = useState(true);
  const [error,    setError]    = useState('');
  const [search,   setSearch]   = useState('');
  const [memberFilter, setMemberFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [kindFilter,   setKindFilter]   = useState('all');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [m, subs, logs] = await Promise.all([
        fetchAllMembers(),
        fetchAllSubmissions(),
        fetchAllWaterLogs(),
      ]);
      setMembers(m);
      const userMap = Object.fromEntries(m.map(u => [u.id, u.name]));

      const taskEntries: TimelineEntry[] = subs.map(s => ({
        id:       s.id,
        kind:     'task',
        title:    s.taskTitle,
        userId:   s.userId,
        userName: userMap[s.userId] ?? s.userId.slice(0,8),
        date:     s.submittedAt,
        status:   s.verificationStatus,
        imageURL: s.imageURL,
        note:     s.note,
        comment:  s.adminComment,
      }));

      const waterEntries: TimelineEntry[] = logs.map(l => ({
        id:       l.id,
        kind:     'water',
        title:    'Hydration Log',
        userId:   l.userId,
        userName: userMap[l.userId] ?? l.userId.slice(0,8),
        date:     l.uploadedAt,
        status:   l.status,
        imageURL: l.imageURL,
        note:     l.note,
        comment:  l.adminComment,
      }));

      const all = [...taskEntries, ...waterEntries].sort(
        (a, b) => b.date.getTime() - a.date.getTime()
      );
      setEntries(all);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  useEffect(() => {
    let res = entries;
    if (memberFilter)          res = res.filter(e => e.userId === memberFilter);
    if (statusFilter !== 'all') res = res.filter(e => e.status === statusFilter);
    if (kindFilter !== 'all')   res = res.filter(e => e.kind   === kindFilter);
    if (search.trim())          res = res.filter(e =>
      e.title.toLowerCase().includes(search.toLowerCase()) ||
      e.userName.toLowerCase().includes(search.toLowerCase())
    );
    setFiltered(res);
  }, [entries, memberFilter, statusFilter, kindFilter, search]);

  const dotClass = (status: string) => {
    if (status === 'verified') return 'green';
    if (status === 'rejected') return 'red';
    return 'yellow';
  };

  const statusBadgeClass = (status: string) => {
    if (status === 'verified') return 'badge-verified';
    if (status === 'rejected') return 'badge-rejected';
    return 'badge-pending';
  };

  const statusLabel = (s: string) =>
    s === 'pending_review' ? 'Pending Review' :
    s === 'verified'       ? 'Verified' : 'Rejected';

  const grouped: Record<string, TimelineEntry[]> = {};
  filtered.forEach(e => {
    const label = dayLabel(e.date);
    if (!grouped[label]) grouped[label] = [];
    grouped[label].push(e);
  });

  return (
    <div>
      <div className="page-header">
        <div>
          <div className="page-title">Activity Timeline</div>
          <div className="page-subtitle">Full submission history across all members</div>
        </div>
        <button className="btn btn-outline" onClick={load}>↻ Refresh</button>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      {/* Filters */}
      <div className="filter-bar">
        <input className="search-input" placeholder="Search…"
          value={search} onChange={e => setSearch(e.target.value)} />

        <select className="form-control" style={{ width:180 }}
          value={memberFilter} onChange={e => setMemberFilter(e.target.value)}>
          <option value="">All Members</option>
          {members.map(m => (
            <option key={m.id} value={m.id}>{m.name}</option>
          ))}
        </select>

        <select className="form-control" style={{ width:150 }}
          value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
          <option value="all">All Statuses</option>
          <option value="pending_review">Pending</option>
          <option value="verified">Verified</option>
          <option value="rejected">Rejected</option>
        </select>

        <select className="form-control" style={{ width:140 }}
          value={kindFilter} onChange={e => setKindFilter(e.target.value)}>
          <option value="all">All Types</option>
          <option value="task">Tasks</option>
          <option value="water">Hydration</option>
        </select>

        <span style={{ marginLeft:'auto', fontSize:'0.8rem', color:'var(--text-secondary)' }}>
          {filtered.length} entries
        </span>
      </div>

      {loading ? (
        <div style={{ textAlign:'center', padding:60 }}>
          <div className="spinner" style={{ margin:'0 auto 12px' }} />
        </div>
      ) : filtered.length === 0 ? (
        <div className="empty-state card">
          <div className="empty-state-icon">🕐</div>
          <div className="empty-state-title">No activity yet</div>
          <div className="empty-state-message">Submissions from members will appear here.</div>
        </div>
      ) : (
        Object.entries(grouped).map(([day, dayEntries]) => (
          <div key={day} style={{ marginBottom:24 }}>
            <div className="section-title">{day}</div>
            <div className="card">
              <div className="card-body" style={{ padding:'8px 20px' }}>
                <div className="timeline">
                  {dayEntries.map(entry => (
                    <div key={entry.id} className="timeline-item">
                      <div className={`timeline-dot ${dotClass(entry.status)}`} />
                      <div className="timeline-content">
                        <div style={{ display:'flex', alignItems:'center', gap:10, flexWrap:'wrap' }}>
                          <span className="timeline-title">{entry.title}</span>
                          <span className={`badge ${statusBadgeClass(entry.status)}`}>
                            {statusLabel(entry.status)}
                          </span>
                          <span className={`badge ${entry.kind === 'water' ? 'badge-active' : 'badge-normal'}`}>
                            {entry.kind === 'water' ? '💧' : '📋'}
                          </span>
                        </div>
                        <div className="timeline-meta">
                          <strong>{entry.userName}</strong> ·{' '}
                          {entry.date.toLocaleTimeString([], { hour:'2-digit', minute:'2-digit' })}
                          {entry.imageURL && ' · 📎 Attachment'}
                        </div>
                        {entry.note && (
                          <div className="timeline-comment">{entry.note}</div>
                        )}
                        {entry.comment && (
                          <div className="timeline-comment" style={{ borderLeftColor:'var(--warning)' }}>
                            💬 Reviewer: {entry.comment}
                          </div>
                        )}
                      </div>
                      {entry.imageURL && (
                        <a href={entry.imageURL} target="_blank" rel="noreferrer">
                          <img src={entry.imageURL} alt=""
                            style={{ width:56, height:56, objectFit:'cover', borderRadius:8,
                              border:'1px solid var(--border)', flexShrink:0 }} />
                        </a>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        ))
      )}
    </div>
  );
}

function dayLabel(d: Date): string {
  const now   = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const day   = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const diff  = Math.round((today.getTime() - day.getTime()) / 86400000);
  if (diff === 0) return 'Today';
  if (diff === 1) return 'Yesterday';
  return d.toLocaleDateString(undefined, { weekday:'long', month:'short', day:'numeric' });
}
