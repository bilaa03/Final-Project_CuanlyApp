import React from 'react';
import { LayoutDashboard, BarChart2, Briefcase, Settings, LogOut, Sparkles, User } from 'lucide-react';

export function Sidebar({ activePage, onNavigate, onOpenChat, user, onLogout }) {
  const menuItems = [
    { id: 'overview', label: 'Overview', icon: LayoutDashboard },
    { id: 'analytics', label: 'Analytics', icon: BarChart2 },
    { id: 'b2b', label: 'B2B Mode', icon: Briefcase },
    { id: 'settings', label: 'Settings', icon: Settings },
  ];

  return (
    <aside className="w-64 bg-cuanly-card border-r border-cuanly-border flex flex-col justify-between h-screen sticky top-0">
      <div className="flex flex-col">
        {/* Brand Header */}
        <div className="p-6 flex items-center space-x-3 border-b border-cuanly-border">
          <img
            src="/images/logo.png"
            alt="Cuanly Logo"
            className="w-10 h-10 object-contain rounded-xl"
            onError={(e) => {
              e.target.style.display = 'none';
              e.target.nextSibling.style.display = 'flex';
            }}
          />
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-cuanly-violet to-cuanly-violetLight hidden items-center justify-center shadow-lg shadow-cuanly-violet/20">
            <span className="text-xl font-bold text-white">C</span>
          </div>
          <div>
            <h1 className="text-lg font-black text-cuanly-textDark tracking-tight">Cuanly</h1>
            <p className="text-[10px] text-cuanly-textMuted font-bold uppercase tracking-wider">Smart Finance Hub</p>
          </div>
        </div>

        {/* User profile brief */}
        {user && (
          <div className="p-4 mx-4 my-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center space-x-3 group">
            <div className="relative flex-shrink-0">
              {/* Pulsing/rotating gradient border ring */}
              <div className="absolute -inset-0.5 bg-gradient-to-tr from-cuanly-violet via-cuanly-mint to-cuanly-violetLight rounded-full blur-[2px] opacity-75 group-hover:opacity-100 transition-opacity duration-300 animate-spin-slow"></div>
              
              <div className="relative w-10 h-10 rounded-full overflow-hidden border border-slate-200 bg-gradient-to-tr from-cuanly-violet/80 via-cuanly-violetLight/80 to-cuanly-mint/40 flex items-center justify-center transition-all duration-500 group-hover:rotate-6">
                {user.avatar ? (
                  <img
                    src={user.avatar}
                    alt="User Avatar"
                    className="w-full h-full object-cover transform group-hover:scale-110 transition-transform duration-300"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <svg className="w-6 h-6 text-white/90 animate-pulse duration-3000" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth="1.5">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
                    </svg>
                  </div>
                )}
              </div>
            </div>
            <div className="overflow-hidden">
              <h4 className="text-xs font-bold text-cuanly-textDark truncate">{user.name}</h4>
              <p className="text-[10px] text-cuanly-textMuted truncate">Personal Plan</p>
            </div>
          </div>
        )}

        {/* Nav Links */}
        <nav className="p-4 space-y-4">
          <div>
            <div className="text-[10px] font-bold text-cuanly-textMuted uppercase tracking-wider px-4 mb-2">Personal (B2C)</div>
            <div className="space-y-1">
              {menuItems.filter(item => item.id === 'overview' || item.id === 'analytics').map((item) => {
                const Icon = item.icon;
                const isActive = activePage === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => onNavigate(item.id)}
                    className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl text-sm font-semibold transition-all duration-200 ${
                      isActive
                        ? 'bg-cuanly-violet text-white shadow-lg shadow-cuanly-violet/20'
                        : 'text-cuanly-textMuted hover:bg-slate-50 hover:text-cuanly-violet'
                    }`}
                  >
                    <Icon size={18} />
                    <span>{item.label}</span>
                  </button>
                );
              })}
            </div>
          </div>

          <div>
            <div className="text-[10px] font-bold text-cuanly-textMuted uppercase tracking-wider px-4 mb-2">Kantor/Tim (B2B)</div>
            <div className="space-y-1">
              {menuItems.filter(item => item.id === 'b2b').map((item) => {
                const Icon = item.icon;
                const isActive = activePage === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => onNavigate(item.id)}
                    className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl text-sm font-semibold transition-all duration-200 ${
                      isActive
                        ? 'bg-cuanly-violet text-white shadow-lg shadow-cuanly-violet/20'
                        : 'text-cuanly-textMuted hover:bg-slate-50 hover:text-cuanly-violet'
                    }`}
                  >
                    <Icon size={18} />
                    <span>{item.label}</span>
                  </button>
                );
              })}
            </div>
          </div>

          <div>
            <div className="text-[10px] font-bold text-cuanly-textMuted uppercase tracking-wider px-4 mb-2">Lainnya</div>
            <div className="space-y-1">
              {menuItems.filter(item => item.id === 'settings').map((item) => {
                const Icon = item.icon;
                const isActive = activePage === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => onNavigate(item.id)}
                    className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl text-sm font-semibold transition-all duration-200 ${
                      isActive
                        ? 'bg-cuanly-violet text-white shadow-lg shadow-cuanly-violet/20'
                        : 'text-cuanly-textMuted hover:bg-slate-50 hover:text-cuanly-violet'
                    }`}
                  >
                    <Icon size={18} />
                    <span>{item.label}</span>
                  </button>
                );
              })}
            </div>
          </div>
        </nav>
      </div>

      {/* Footer Actions */}
      <div className="p-4 space-y-2">
        <button
          onClick={onOpenChat}
          className="w-full flex items-center justify-center space-x-2 px-4 py-3 rounded-xl text-sm font-bold bg-cuanly-mint/10 text-cuanly-mint border border-cuanly-mint/20 hover:bg-cuanly-mint/20 transition-all duration-200"
        >
          <Sparkles size={16} />
          <span>Ask Cuanly</span>
        </button>

        <button
          onClick={onLogout}
          className="w-full flex items-center space-x-3 px-4 py-3 rounded-xl text-sm font-semibold text-cuanly-red hover:bg-cuanly-red/10 transition-all duration-200"
        >
          <LogOut size={18} />
          <span>Logout</span>
        </button>
      </div>
    </aside>
  );
}
