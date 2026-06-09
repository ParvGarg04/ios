import React, { useEffect, useState, useCallback } from 'react';
import { fetchAllMembers, fetchAllTasks, createTask, updateTask, deleteTask } from '../hooks/useFirestore';
import { TaskItem, UserProfile } from '../types';
import { useAuth } from '../hooks/useAuth';

const EMPTY_TASK: Omit<TaskItem,'id'|'createdAt'|'assignedBy'> = {
  taskId: '',
  userId: '',
  title: '',
  description: '',
  type: 'simple',
  dueTime: undefined,
  repeatInterval: 'none',
  priority: 'normal',
  requiresProof: false,
  isActive: true,
};

export default function TasksPage() {
  const { user } = useAuth();
  const [tasks,   setTasks]   = useState<TaskItem[]>([]);
  const [members, setMembers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [error,   setError]   = useState('');
  const [search,  setSearch]  = useState('');
  const [modal,   setModal]   = useState(false);
  const [editing, setEditing] = useState<TaskItem | null>(null);
  const [saving,  setSaving]  = useState(false);
  const [toast,   setToast]   = useState('');
  const [form,    setForm]    = useState({ ...EMPTY_TASK });
  const [dueTimeStr, setDueTimeStr] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [t, m] = await Promise.all([fetchAllTasks(), fetchAllMembers()]);
      setTasks(t);
      setMembers(m);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(''), 3000);
  };

  const openCreate = () => {
    setEditing(null);
    setForm({ ...EMPTY_TASK });
    setDueTimeStr('');
    setModal(true);
  };

  const openEdit = (task: TaskItem) => {
    setEditing(task);
    setForm({
      taskId:           task.taskId,
      userId:           task.userId,
      title:            task.title,
      description:      task.description,
      type:             task.type,
      dueTime:          task.dueTime,
      repeatInterval:   task.repeatInterval,
      priority:         task.priority,
      requiresProof:    task.requiresProof,
      isActive:         task.isActive,
    });
    setDueTimeStr(task.dueTime ? toLocalDatetimeString(task.dueTime) : '');
    setModal(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()) { setError('Task title is required.'); return; }
    if (!form.userId)       { setError('Please select a member.'); return; }
    setSaving(true);
    setError('');
    try {
      const taskData = {
        ...form,
        taskId:     editing?.taskId ?? crypto.randomUUID(),
        dueTime:    dueTimeStr ? new Date(dueTimeStr) : undefined,
        assignedBy: user?.uid ?? '',
        createdAt:  editing?.createdAt ?? new Date(),
      };
      if (editing) {
        await updateTask(editing.id, taskData);
        showToast('✅ Task updated successfully');
      } else {
        await createTask(taskData as TaskItem);
        showToast('✅ Task created and assigned');
      }
      setModal(false);
      await load();
    } catch (e: any) {
      setError('Save failed: ' + e.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (task: TaskItem) => {
    if (!window.confirm(`Archive task "${task.title}"? It will be removed for the member.`)) return;
    try {
      await deleteTask(task.id);
      showToast('🗑 Task archived');
      await load();
    } catch (e: any) {
      setError('Delete failed: ' + e.message);
    }
  };

  const filtered = tasks.filter(t =>
    t.isActive &&
    (t.title.toLowerCase().includes(search.toLowerCase()) ||
     members.find(m => m.id === t.userId)?.name.toLowerCase().includes(search.toLowerCase()) ||
     false)
  );

  const memberName = (id: string) => members.find(m => m.id === id)?.name ?? id.slice(0,8);

  const priorityClass = (p: string) =>
    p === 'urgent' ? 'badge-urgent' : p === 'important' ? 'badge-important' : 'badge-normal';

  return (
    <div>
      {toast && (
        <div style={{
          position:'fixed', top:20, right:20, zIndex:999,
          background:'#fff', border:'1px solid var(--border)',
          borderRadius:10, padding:'12px 18px',
          boxShadow:'var(--shadow-md)', fontWeight:500, fontSize:'0.875rem'
        }}>{toast}</div>
      )}

      <div className="page-header">
        <div>
          <div className="page-title">Tasks</div>
          <div className="page-subtitle">Manage and assign tasks to members</div>
        </div>
        <button className="btn btn-primary" onClick={openCreate}>+ New Task</button>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      <div className="filter-bar">
        <input
          className="search-input"
          placeholder="Search tasks or members…"
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
        <span style={{ marginLeft:'auto', fontSize:'0.8rem', color:'var(--text-secondary)' }}>
          {filtered.length} active task{filtered.length !== 1 ? 's' : ''}
        </span>
      </div>

      {loading ? (
        <div style={{ textAlign:'center', padding:60 }}>
          <div className="spinner" style={{ margin:'0 auto 12px' }} />
        </div>
      ) : filtered.length === 0 ? (
        <div className="empty-state card">
          <div className="empty-state-icon">📋</div>
          <div className="empty-state-title">No tasks yet</div>
          <div className="empty-state-message">Create a task to assign to a member.</div>
        </div>
      ) : (
        <div className="card">
          <div className="table-wrapper">
            <table className="table">
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Member</th>
                  <th>Priority</th>
                  <th>Type</th>
                  <th>Due Time</th>
                  <th>Repeat</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(task => (
                  <tr key={task.id}>
                    <td>
                      <div style={{ fontWeight:500 }}>{task.title}</div>
                      {task.description && (
                        <div style={{ fontSize:'0.78rem', color:'var(--text-secondary)', marginTop:2 }}>
                          {task.description.slice(0,60)}{task.description.length > 60 ? '…' : ''}
                        </div>
                      )}
                    </td>
                    <td>
                      <div style={{ display:'flex', alignItems:'center', gap:8 }}>
                        <div className="member-avatar">{memberName(task.userId)[0]?.toUpperCase()}</div>
                        {memberName(task.userId)}
                      </div>
                    </td>
                    <td><span className={`badge ${priorityClass(task.priority)}`}>{task.priority}</span></td>
                    <td>
                      <span className="badge badge-normal">
                        {task.requiresProof ? '📎 Proof' : '☑ Simple'}
                      </span>
                    </td>
                    <td style={{ fontSize:'0.82rem', color:'var(--text-secondary)' }}>
                      {task.dueTime ? task.dueTime.toLocaleTimeString([], {hour:'2-digit',minute:'2-digit'}) : '—'}
                    </td>
                    <td>
                      <span className="badge badge-normal">{task.repeatInterval}</span>
                    </td>
                    <td>
                      <div style={{ display:'flex', gap:6 }}>
                        <button className="btn btn-ghost btn-sm" onClick={() => openEdit(task)}>✏️</button>
                        <button className="btn btn-ghost btn-sm" onClick={() => handleDelete(task)}>🗑</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Create / Edit Modal */}
      {modal && (
        <div className="modal-overlay" onClick={() => !saving && setModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:20 }}>
              <div className="modal-title" style={{ margin:0 }}>{editing ? 'Edit Task' : 'Create New Task'}</div>
              <button className="btn btn-ghost btn-icon" onClick={() => setModal(false)}>✕</button>
            </div>

            {error && <div className="alert alert-danger">{error}</div>}

            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">Assign to Member *</label>
                <select className="form-control" value={form.userId}
                  onChange={e => setForm(f => ({...f, userId: e.target.value}))}>
                  <option value="">Select a member…</option>
                  {members.map(m => (
                    <option key={m.id} value={m.id}>{m.name}</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Task Title *</label>
                <input className="form-control" placeholder="e.g. Complete homework" required
                  value={form.title} onChange={e => setForm(f => ({...f, title: e.target.value}))} />
              </div>

              <div className="form-group">
                <label className="form-label">Description</label>
                <textarea className="form-control" rows={2} placeholder="Optional details…"
                  value={form.description}
                  onChange={e => setForm(f => ({...f, description: e.target.value}))} />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label className="form-label">Priority</label>
                  <select className="form-control" value={form.priority}
                    onChange={e => setForm(f => ({...f, priority: e.target.value as any}))}>
                    <option value="normal">Normal</option>
                    <option value="important">Important</option>
                    <option value="urgent">Urgent</option>
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Repeat</label>
                  <select className="form-control" value={form.repeatInterval}
                    onChange={e => setForm(f => ({...f, repeatInterval: e.target.value as any}))}>
                    <option value="none">One-time</option>
                    <option value="daily">Daily</option>
                    <option value="weekly">Weekly</option>
                    <option value="hourly">Every Hour</option>
                  </select>
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label className="form-label">Due Date & Time</label>
                  <input type="datetime-local" className="form-control"
                    value={dueTimeStr} onChange={e => setDueTimeStr(e.target.value)} />
                </div>
                <div className="form-group" style={{ display:'flex', alignItems:'flex-end' }}>
                  <label className="checkbox-label" style={{ paddingBottom:2 }}>
                    <input type="checkbox" checked={form.requiresProof}
                      onChange={e => setForm(f => ({...f, requiresProof: e.target.checked}))} />
                    Requires attachment (photo proof)
                  </label>
                </div>
              </div>

              <div className="modal-actions">
                <button type="button" className="btn btn-outline" onClick={() => setModal(false)} disabled={saving}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? <><span className="spinner" style={{width:14,height:14}} /> Saving…</> :
                    (editing ? '💾 Update Task' : '✚ Create Task')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

function toLocalDatetimeString(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
