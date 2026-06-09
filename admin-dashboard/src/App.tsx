import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './hooks/useAuth';
import LoginPage    from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import ReviewsPage  from './pages/ReviewsPage';
import TasksPage    from './pages/TasksPage';
import TimelinePage from './pages/TimelinePage';
import MembersPage  from './pages/MembersPage';
import Sidebar      from './components/Sidebar';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, profile, loading } = useAuth();

  if (loading) {
    return (
      <div style={{ display:'flex', alignItems:'center', justifyContent:'center', height:'100vh', gap:12, background:'var(--bg)' }}>
        <div className="spinner" />
        <span style={{ color:'var(--text-secondary)' }}>Loading…</span>
      </div>
    );
  }

  if (!user) return <Navigate to="/login" replace />;
  if (profile && profile.role !== 'admin') {
    return (
      <div style={{ display:'flex', alignItems:'center', justifyContent:'center', height:'100vh', background:'var(--bg)' }}>
        <div style={{ textAlign:'center', padding:40 }}>
          <div style={{ fontSize:'3rem', marginBottom:16 }}>🔒</div>
          <h2 style={{ marginBottom:8 }}>Access Denied</h2>
          <p style={{ color:'var(--text-secondary)' }}>Admin access required.</p>
          <button className="btn btn-primary" style={{ marginTop:20 }}
            onClick={() => { import('./firebase').then(m => m.auth.signOut()); }}>
            Sign Out
          </button>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}

function AppLayout() {
  return (
    <div className="app-layout">
      <Sidebar />
      <main className="main-content">
        <Routes>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="reviews"   element={<ReviewsPage />} />
          <Route path="tasks"     element={<TasksPage />} />
          <Route path="timeline"  element={<TimelinePage />} />
          <Route path="members"   element={<MembersPage />} />
          <Route path="*"         element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </main>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/*" element={
          <ProtectedRoute>
            <AppLayout />
          </ProtectedRoute>
        } />
      </Routes>
    </BrowserRouter>
  );
}
