import React, { useState, useEffect } from 'react';
import { CreditCard, User, Upload } from 'lucide-react';

export function Settings({ budgetLimit, onUpdateBudgetLimit, wallets, onAddWallet, user, onUpdateProfile }) {
  const [walletName, setWalletName] = useState('');
  const [walletBalance, setWalletBalance] = useState('');
  const [walletCardNumber, setWalletCardNumber] = useState('');
  const [walletDesign, setWalletDesign] = useState('blue');

  // Profile states
  const [profileName, setProfileName] = useState(user?.name || '');
  const [profileEmail, setProfileEmail] = useState(user?.email || '');
  const [profileAvatar, setProfileAvatar] = useState(user?.avatar || '/images/avatar.png');

  // Sync profile details when user prop changes
  useEffect(() => {
    if (user) {
      setProfileName(user.name);
      setProfileEmail(user.email);
      if (user.avatar) {
        setProfileAvatar(user.avatar);
      }
    }
  }, [user]);

  const handleAvatarChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setProfileAvatar(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleUpdateProfileSubmit = (e) => {
    e.preventDefault();
    if (!profileName.trim() || !profileEmail.trim()) {
      alert('Nama dan Email tidak boleh kosong!');
      return;
    }
    onUpdateProfile(profileName.trim(), profileEmail.trim(), profileAvatar);
    alert('Profil Anda berhasil diperbarui!');
  };

  const handleAddWalletSubmit = (e) => {
    e.preventDefault();
    if (!walletName || !walletBalance || !walletCardNumber) {
      alert('Mohon isi semua bidang dompet!');
      return;
    }
    onAddWallet(walletName, Number(walletBalance), walletCardNumber, walletDesign);
    setWalletName('');
    setWalletBalance('');
    setWalletCardNumber('');
    alert('Dompet baru berhasil ditambahkan!');
  };

  return (
    <div className="flex-1 p-8 overflow-y-auto bg-cuanly-bg text-cuanly-textDark">
      <div className="mb-8">
        <h2 className="text-2xl font-black tracking-tight">Pengaturan</h2>
        <p className="text-sm text-cuanly-textMuted mt-1">Konfigurasi profil personal dan dompet akun Anda.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* User Profile Settings Form */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 shadow-sm shadow-slate-100">
          <div className="flex items-center space-x-2 text-cuanly-violet mb-6">
            <User size={20} />
            <h3 className="text-base font-bold text-cuanly-textDark">Profil Pengguna</h3>
          </div>

          <form onSubmit={handleUpdateProfileSubmit} className="space-y-5">
            {/* Avatar upload representation */}
            <div className="flex items-center space-x-4 p-4 rounded-xl bg-slate-50 border border-slate-200/50">
              <div className="relative w-16 h-16 rounded-full overflow-hidden border-2 border-cuanly-violet/40 bg-gradient-to-tr from-cuanly-violet/80 via-cuanly-violetLight/80 to-cuanly-mint/40 flex items-center justify-center">
                {profileAvatar ? (
                  <img
                    src={profileAvatar}
                    alt="Current Avatar"
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <svg className="w-8 h-8 text-white/90 animate-pulse duration-3000" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth="1.5">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
                  </svg>
                )}
              </div>
              <div className="flex-1">
                <label className="text-xs text-cuanly-textDark font-bold block mb-1">Foto Profil Baru</label>
                <div className="relative">
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleAvatarChange}
                    id="avatar-upload-input"
                    className="hidden"
                  />
                  <label
                    htmlFor="avatar-upload-input"
                    className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-lg bg-cuanly-violet/10 hover:bg-cuanly-violet/20 border border-cuanly-violet/20 text-[11px] font-bold text-cuanly-violet cursor-pointer transition-colors"
                  >
                    <Upload size={12} />
                    <span>Pilih Berkas Foto</span>
                  </label>
                </div>
              </div>
            </div>

            <div>
              <label className="text-xs text-cuanly-textMuted block mb-2">Nama Lengkap</label>
              <input
                type="text"
                value={profileName}
                onChange={(e) => setProfileName(e.target.value)}
                placeholder="Masukkan nama lengkap"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm text-cuanly-textDark focus:border-cuanly-violet focus:outline-none placeholder-slate-400"
              />
            </div>

            <div>
              <label className="text-xs text-cuanly-textMuted block mb-2">Alamat Email</label>
              <input
                type="email"
                value={profileEmail}
                onChange={(e) => setProfileEmail(e.target.value)}
                placeholder="bilaa@cuanly.ai"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm text-cuanly-textDark focus:border-cuanly-violet focus:outline-none placeholder-slate-400"
              />
            </div>

            <button
              type="submit"
              className="w-full py-3 rounded-xl text-xs font-bold bg-cuanly-violet text-white hover:opacity-90 transition-opacity"
            >
              Simpan Profil Anda
            </button>
          </form>
        </div>

        {/* Add Wallet Form */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 shadow-sm shadow-slate-100">
          <div className="flex items-center space-x-2 text-cuanly-mint mb-6">
            <CreditCard size={20} />
            <h3 className="text-base font-bold text-cuanly-textDark">Tambah Dompet Baru</h3>
          </div>

          <form onSubmit={handleAddWalletSubmit} className="space-y-4">
            <div>
              <label className="text-xs text-cuanly-textMuted block mb-2">Nama Dompet (e.g. Bank Mandiri, GoPay)</label>
              <input
                type="text"
                value={walletName}
                onChange={(e) => setWalletName(e.target.value)}
                placeholder="Mandiri, Gopay, OVO..."
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm text-cuanly-textDark focus:border-cuanly-violet focus:outline-none placeholder-slate-400"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-cuanly-textMuted block mb-2">Saldo Awal</label>
                <input
                  type="number"
                  value={walletBalance}
                  onChange={(e) => setWalletBalance(e.target.value)}
                  placeholder="3000000"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm text-cuanly-textDark focus:border-cuanly-violet focus:outline-none placeholder-slate-400"
                />
              </div>
              <div>
                <label className="text-xs text-cuanly-textMuted block mb-2">Nomor Kartu / HP</label>
                <input
                  type="text"
                  value={walletCardNumber}
                  onChange={(e) => setWalletCardNumber(e.target.value)}
                  placeholder="•••• 1234 atau HP"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm text-cuanly-textDark focus:border-cuanly-violet focus:outline-none placeholder-slate-400"
                />
              </div>
            </div>

            <div>
              <label className="text-xs text-cuanly-textMuted block mb-2">Desain Warna Kartu</label>
              <div className="flex space-x-3">
                {['blue', 'teal', 'purple', 'slate'].map((theme) => (
                  <button
                    key={theme}
                    type="button"
                    onClick={() => setWalletDesign(theme)}
                    className={`w-10 h-10 rounded-xl border-2 transition-all ${
                      walletDesign === theme ? 'border-cuanly-violet scale-110' : 'border-transparent opacity-60'
                    } ${
                      theme === 'blue' ? 'bg-blue-600' :
                      theme === 'teal' ? 'bg-teal-600' :
                      theme === 'purple' ? 'bg-purple-600' : 'bg-slate-600'
                    }`}
                  ></button>
                ))}
              </div>
            </div>

            <button
              type="submit"
              className="w-full py-3 rounded-xl text-xs font-bold bg-cuanly-mint text-white hover:opacity-90 transition-opacity"
            >
              Tambah Dompet Baru
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
