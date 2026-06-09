import React, { useEffect, useState, useCallback } from 'react';
import {
  fetchPendingReviews, fetchAllMembers,
  reviewSubmission, reviewWaterLog,
} from '../hooks/useFirestore';
import { ReviewItem } from '../types';

export default function ReviewsPage() {
  const [items,     setItems]     = useState<ReviewItem[]>([]);
  const [filtered,  setFiltered]  = useState<ReviewItem[]>([]);
  const [loading,   setLoading]   = useState(true);
  const [error,     setError]     = useState('');
  const [filter,    setFilter]    = useState<'all'|'task'|'water'>('all');
  const [search,    setSearch]    = useState('');
  const [modal,     setModal]     = useState<ReviewItem | null>(null);
  const [comment,   setComment]   = useState('');
  const [saving,    setSaving]    = useState(false);
  const [toast,     setToast]     = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const members = await fetchAllMembers();
      const userMap = Object.fromEntries(members.map(m => [m.id, m.name]));
      const all = await fetchPendingReviews(userMap);
      setItems(all);
    } catch (e: any) {
      setError('Failed to load reviews: ' + e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  useEffect(() => {
    let res = items;
    if (filter !== 'all') res = res.filter(i => i.kind === filter);
    if (search.trim())    res = res.filter(i =>
      i.title.toLowerCase().includes(search.toLowerCase()) ||
      (i.userName ?? '').toLowerCase().includes(search.toLowerCase())
    );
    setFiltered(res);
  }, [items, filter, search]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(''), 3000);
  };

  const handleReview = async (status: 'verified' | 'rejected') => {
    if (!modal) return;
    setSaving(true);
    try {
      if (modal.kind === 'task') {
        await reviewSubmission(modal.id, status, comment);
      } else {
        await reviewWaterLog(modal.id, status, comment);
      }
      showToast(status === 'verified' ? '✅ Verified successfully' : '❌ Marked as rejected');
      setModal(null);
      setComment('');
      await load();
    } catch (e: any) {
      setError('Review failed: ' + e.message);
    } finally {
      setSaving(false);
    }
  };

  const fmtDate = (d: Date) => {
    const diff = (Date.now() - d.getTime()) / 1000;
    if (diff < 60)   return 'Just now';
    if (diff < 3600) return `${Math.floor(diff/60)}m ago`;
    if (diff < 86400)return `${Math.floor(diff/3600)}h ago`;
    return d.toLocaleString();
  };

  return (
    <div>
      {/* Toast */}
      {toast && (
        <div style={{
          position:'fixed', top:20, right:20, zIndex:999,
          background:'#fff', border:'1px solid var(--border)',
          borderRadius:10, padding:'12px 18px',
          boxShadow:'var(--shadow-md)', fontWeight:500, fontSize:'0.875rem'
        }}>
          {toast}
        </div>
      )}

      <div className="page-header">
        <div>
          <div className="page-title">Pending Reviews</div>
          <div className="page-subtitle">
            {items.length > 0 ? `${items.length} item${items.length !== 1 ? 's' : ''} awaiting review` : 'All reviews are up to date'}
          </div>
        </div>
        <button className="btn btn-outline" onClick={load}>↻ Refresh</button>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      {/* Filter bar */}
      <div className="filter-bar">
        <input
          type="text"
          className="search-input"
          placeholder="Search by title or member…"
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
        {(['all','task','water'] as const).map(f => (
          <button key={f}
            className={`btn ${filter === f ? 'btn-primary' : 'btn-outline'} btn-sm`}
            onClick={() => setFilter(f)}>
            {f === 'all' ? 'All' : f === 'task' ? '📋 Tasks' : '💧 Hydration'}
          </button>
        ))}
        <span style={{ marginLeft:'auto', fontSize:'0.8rem', color:'var(--text-secondary)' }}>
          {filtered.length} result{filtered.length !== 1 ? 's' : ''}
        </span>
      </div>

      {loading ? (
        <div style={{ textAlign:'center', padding:60 }}>
          <div className="spinner" style={{ margin:'0 auto 12px' }} />
          <p style={{ color:'var(--text-secondary)' }}>Loading reviews…</p>
        </div>
      ) : filtered.length === 0 ? (
        <div className="empty-state card">
          <div className="empty-state-icon">🎉</div>
          <div className="empty-state-title">No pending reviews</div>
          <div className="empty-state-message">All submissions have been reviewed.</div>
        </div>
      ) : (
        <div className="review-cards">
          {filtered.map(item => (
            <ReviewCard
              key={item.id}
              item={item}
              fmtDate={fmtDate}
              onReview={() => { setModal(item); setComment(item.adminComment ?? ''); }}
            />
          ))}
        </div>
      )}

      {/* Review Modal */}
      {modal && (
        <div className="modal-overlay" onClick={() => !saving && setModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:20 }}>
              <div className="modal-title" style={{ margin:0 }}>
                Review — {modal.title}
              </div>
              <button className="btn btn-ghost btn-icon" onClick={() => setModal(null)}>✕</button>
            </div>

            {/* Submission info */}
            <div style={{ background:'var(--bg)', borderRadius:10, padding:14, marginBottom:18, fontSize:'0.85rem' }}>
              <div style={{ display:'flex', gap:8, flexWrap:'wrap', marginBottom:8 }}>
                <span className={`badge ${modal.kind === 'water' ? 'badge-active' : 'badge-normal'}`}>
                  {modal.kind === 'water' ? '💧 Hydration' : '📋 Task'}
                </span>
                <span className="badge badge-pending">⏳ Pending Review</span>
              </div>
              <div style={{ color:'var(--text-secondary)' }}>
                <strong>Member:</strong> {modal.userName ?? modal.userId}<br />
                <strong>Submitted:</strong> {fmtDate(modal.submittedAt)}
              </div>
              {modal.note && (
                <div className="review-card-note" style={{ marginTop:10 }}>
                  📝 {modal.note}
                </div>
              )}
            </div>

            {/* Image */}
            {modal.imageURL && (
              <div style={{ marginBottom:18 }}>
                <img
                  src={modal.imageURL}
                  alt="Submission"
                  style={{
                    width:'100%', maxHeight:280, objectFit:'cover',
                    borderRadius:10, border:'1px solid var(--border)'
                  }}
                />
                <a href={modal.imageURL} target="_blank" rel="noreferrer"
                  style={{ fontSize:'0.78rem', color:'var(--accent)', display:'block', marginTop:6 }}>
                  Open full image ↗
                </a>
              </div>
            )}

            {/* Comment */}
            <div className="form-group">
              <label className="form-label">Reviewer Note (optional)</label>
              <textarea
                className="form-control"
                rows={3}
                placeholder="Add a note visible to the member…"
                value={comment}
                onChange={e => setComment(e.target.value)}
              />
            </div>

            <div className="modal-actions">
              <button className="btn btn-outline" onClick={() => setModal(null)} disabled={saving}>
                Cancel
              </button>
              <button className="btn btn-danger" onClick={() => handleReview('rejected')} disabled={saving}>
                {saving ? <span className="spinner" style={{width:14,height:14}} /> : '✕'} Reject
              </button>
              <button className="btn btn-success" onClick={() => handleReview('verified')} disabled={saving}>
                {saving ? <span className="spinner" style={{width:14,height:14}} /> : '✓'} Verify
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function ReviewCard({ item, fmtDate, onReview }: {
  item: ReviewItem;
  fmtDate: (d: Date) => string;
  onReview: () => void;
}) {
  return (
    <div className="review-card">
      <div className="review-card-image">
        {item.imageURL
          ? <img src={item.imageURL} alt="submission" loading="lazy" />
          : <span>No attachment</span>
        }
      </div>

      <div className="review-card-body">
        <div style={{ display:'flex', gap:8, marginBottom:8, flexWrap:'wrap' }}>
          <span className={`badge ${item.kind === 'water' ? 'badge-active' : 'badge-normal'}`}>
            {item.kind === 'water' ? '💧 Hydration' : '📋 Task'}
          </span>
          <span className="badge badge-pending">⏳ Pending</span>
        </div>
        <div className="review-card-title">{item.title}</div>
        <div className="review-card-meta">
          By <strong>{item.userName ?? item.userId}</strong> · {fmtDate(item.submittedAt)}
        </div>
        {item.note && (
          <div className="review-card-note">📝 {item.note}</div>
        )}
      </div>

      <div className="review-card-actions">
        <button className="btn btn-success btn-sm" onClick={onReview} style={{justifyContent:'center'}}>
          ✓ Verify
        </button>
        <button className="btn btn-danger btn-sm" onClick={onReview} style={{justifyContent:'center'}}>
          ✕ Reject
        </button>
        <button className="btn btn-outline btn-sm" onClick={onReview} style={{justifyContent:'center'}}>
          💬 Review
        </button>
      </div>
    </div>
  );
}
