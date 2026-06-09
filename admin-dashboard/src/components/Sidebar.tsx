import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

const navItems = [
  { path: '/dashboard', label: 'Dashboard',  icon: '✦' },
  { path: '/reviews',   label: 'Reviews',    icon: '✓' },
  { path: '/tasks',     label: 'Tasks',      icon: '☑' },
  { path: '/timeline',  label: 'Timeline',   icon: '◷' },
  { path: '/members',   label: 'Members',    icon: '♡' },
];

export default function Sidebar() {
  const { profile, signOut } = useAuth();
  const navigate = useNavigate();

  const handleSignOut = async () => {
    await signOut();
    navigate('/login');
  };

  const initials = profile?.name
    ? profile.name.split(' ').map(p => p[0]).join('').slice(0,2).toUpperCase()
    : 'AD';

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <div className="sidebar-logo">
          <div className="sidebar-logo-icon">♡</div>
          DailyFlow
        </div>
        <div className="sidebar-subtitle">Admin Console</div>
      </div>

      <nav className="sidebar-nav">
        {navItems.map(item => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
          >
            <span className="nav-link-icon">{item.icon}</span>
            {item.label}
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12 }}>
          <div className="member-avatar">{initials}</div>
          <div>
            <div className="sidebar-user-name">{profile?.name ?? 'Admin'}</div>
            <div className="sidebar-user-role">Reviewer · Admin</div>
          </div>
        </div>
        <button className="btn btn-ghost" style={{ width:'100%', justifyContent:'flex-start' }}
          onClick={handleSignOut}>
          ↩ Sign Out
        </button>
      </div>
    </aside>
  );
}
