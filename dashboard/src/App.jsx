import React, { useState } from 'react';
import { useFinancialState } from './hooks/useFinancialState';
import { Sidebar } from './components/Sidebar';
import { ChatPanel } from './components/ChatPanel';
import { Overview } from './pages/Overview';
import { Analytics } from './pages/Analytics';
import { B2BFinance } from './pages/B2BFinance';
import { Settings } from './pages/Settings';
import { Sparkles, Eye, EyeOff } from 'lucide-react';

function App() {
  const {
    user,
    wallets,
    transactions,
    budgetLimit,
    loading,
    error,
    totalSaldo,
    totalPemasukan,
    totalPengeluaran,
    savingRatio,
    budgetPct,
    login,
    register,
    logout,
    addWallet,
    updateBudgetLimit,
    updateProfile
  } = useFinancialState();

  const [activePage, setActivePage] = useState('overview');
  const [isChatOpen, setIsChatOpen] = useState(false);

  // Auth local state
  const [isLoginMode, setIsLoginMode] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [authError, setAuthError] = useState('');

  const handleAuthSubmit = async (e) => {
    e.preventDefault();
    setAuthError('');
    if (isLoginMode) {
      const success = await login(email, password);
      if (!success) {
        setAuthError('Email atau password tidak sesuai. Gunakan: bilaa@cuanly.ai / password123');
      }
    } else {
      const success = await register(name, email, password);
      if (success) {
        alert('Registrasi sukses! Silakan login.');
        setIsLoginMode(true);
      } else {
        setAuthError('Gagal register. Akun email mungkin sudah terdaftar.');
      }
    }
  };

  const handleDemoLogin = async () => {
    setEmail('bilaa@cuanly.ai');
    setPassword('password123');
    const success = await login('bilaa@cuanly.ai', 'password123');
    if (!success) {
      setAuthError('Koneksi database bermasalah. Menggunakan fallback mode lokal.');
    }
  };

  // Render auth view if user is not logged in
  if (!user) {
    return (
      <div className="min-h-screen bg-cuanly-bg flex items-center justify-center p-4 relative overflow-hidden font-sans">
        {/* Decorative background glow circles */}
        <div className="absolute top-1/4 left-1/4 w-[35rem] h-[35rem] bg-cuanly-violet/10 rounded-full blur-3xl -z-10 animate-pulse"></div>
        <div className="absolute bottom-1/4 right-1/4 w-[30rem] h-[30rem] bg-cuanly-mint/5 rounded-full blur-3xl -z-10"></div>

        <div className="max-w-md w-full bg-cuanly-card border border-cuanly-border rounded-3xl p-8 shadow-2xl relative overflow-hidden">
          {/* Header Brand */}
          <div className="text-center mb-8">
            <img
              src="/images/logo.png"
              alt="Cuanly Logo"
              className="w-14 h-14 object-contain mx-auto mb-4 rounded-2xl"
              onError={(e) => {
                e.target.style.display = 'none';
                e.target.nextSibling.style.display = 'flex';
              }}
            />
            <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-cuanly-violet to-cuanly-violetLight hidden items-center justify-center mx-auto shadow-xl shadow-cuanly-violet/30 mb-4">
              <span className="text-2xl font-black text-white">C</span>
            </div>
            <h1 className="text-2xl font-black tracking-tight text-white">Selamat Datang di Cuanly</h1>
            <p className="text-xs text-cuanly-textMuted mt-1">Kelola anggaran cerdas dibantu asisten Cuanly.</p>
          </div>

          {authError && (
            <div className="p-4 mb-4 rounded-xl bg-cuanly-red/10 border border-cuanly-red/20 text-xs font-semibold text-cuanly-red">
              ⚠️ {authError}
            </div>
          )}

          <form onSubmit={handleAuthSubmit} className="space-y-4">
            {!isLoginMode && (
              <div>
                <label className="text-[10px] text-cuanly-textMuted font-bold uppercase tracking-wider block mb-1.5">Nama Lengkap</label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Masukkan nama lengkap"
                  className="w-full bg-white/5 border border-cuanly-border rounded-xl px-4 py-3 text-xs focus:border-cuanly-violet focus:outline-none text-white"
                />
              </div>
            )}

            <div>
              <label className="text-[10px] text-cuanly-textMuted font-bold uppercase tracking-wider block mb-1.5">Alamat Email</label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="nama@email.com"
                className="w-full bg-white/5 border border-cuanly-border rounded-xl px-4 py-3 text-xs focus:border-cuanly-violet focus:outline-none text-white"
              />
            </div>

            <div>
              <label className="text-[10px] text-cuanly-textMuted font-bold uppercase tracking-wider block mb-1.5">Kata Sandi</label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-white/5 border border-cuanly-border rounded-xl pl-4 pr-10 py-3 text-xs focus:border-cuanly-violet focus:outline-none text-white"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-cuanly-textMuted hover:text-white"
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              className="w-full py-3.5 rounded-xl text-xs font-black bg-gradient-to-r from-cuanly-violet to-cuanly-violetLight text-white shadow-lg shadow-cuanly-violet/30 hover:opacity-95 transition-opacity"
            >
              {isLoginMode ? 'Login ke Akun' : 'Daftar Akun Baru'}
            </button>
          </form>

          {/* Quick Demo Credentials shortcut */}
          {isLoginMode && (
            <button
              onClick={handleDemoLogin}
              className="w-full mt-3 py-3 rounded-xl text-xs font-bold bg-white/5 border border-cuanly-border hover:bg-white/10 text-white flex items-center justify-center space-x-1.5 transition-colors"
            >
              <Sparkles size={14} className="text-cuanly-violetLight" />
              <span>Login Demo Akun (Bilaa)</span>
            </button>
          )}

          <div className="text-center mt-6">
            <button
              onClick={() => {
                setAuthError('');
                setIsLoginMode(!isLoginMode);
              }}
              className="text-xs font-bold text-cuanly-violetLight hover:underline"
            >
              {isLoginMode ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Login'}
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Render main layout pages
  const renderActivePage = () => {
    switch (activePage) {
      case 'overview':
        return (
          <Overview
            totalSaldo={totalSaldo}
            totalPemasukan={totalPemasukan}
            totalPengeluaran={totalPengeluaran}
            budgetLimit={budgetLimit}
            savingRatio={savingRatio}
            budgetPct={budgetPct}
            transactions={transactions}
            wallets={wallets}
            onNavigate={setActivePage}
            onOpenChat={() => setIsChatOpen(true)}
          />
        );
      case 'analytics':
        return <Analytics transactions={transactions} budgetLimit={budgetLimit} />;
      case 'b2b':
        return <B2BFinance />;
      case 'settings':
        return (
          <Settings
            budgetLimit={budgetLimit}
            onUpdateBudgetLimit={updateBudgetLimit}
            wallets={wallets}
            onAddWallet={addWallet}
            user={user}
            onUpdateProfile={updateProfile}
          />
        );
      default:
        return (
          <Overview
            totalSaldo={totalSaldo}
            totalPemasukan={totalPemasukan}
            totalPengeluaran={totalPengeluaran}
            budgetLimit={budgetLimit}
            savingRatio={savingRatio}
            budgetPct={budgetPct}
            transactions={transactions}
            wallets={wallets}
            onNavigate={setActivePage}
            onOpenChat={() => setIsChatOpen(true)}
          />
        );
    }
  };

  return (
    <div className="min-h-screen bg-cuanly-bg flex font-sans overflow-hidden">
      {/* Sidebar Navigation */}
      <Sidebar
        activePage={activePage}
        onNavigate={setActivePage}
        onOpenChat={() => setIsChatOpen(true)}
        user={user}
        onLogout={logout}
      />

      {/* Main Panel View Area */}
      <main className="flex-1 flex flex-col h-screen overflow-hidden">
        {renderActivePage()}
      </main>

      {/* Cuanly sliding side Drawer Panel */}
      <ChatPanel
        isOpen={isChatOpen}
        onClose={() => setIsChatOpen(false)}
        user={user}
        transactions={transactions}
      />
    </div>
  );
}

export default App;
