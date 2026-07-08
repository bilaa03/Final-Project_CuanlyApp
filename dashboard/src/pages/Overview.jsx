import React, { useState } from 'react';
import { 
  TrendingUp, 
  TrendingDown, 
  Wallet, 
  PieChart, 
  Sparkles, 
  Calendar,
  DollarSign,
  ArrowUpRight,
  Plus,
  Bell
} from 'lucide-react';
import { 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer 
} from 'recharts';

export function Overview({ 
  totalSaldo, 
  totalPemasukan, 
  totalPengeluaran, 
  budgetLimit, 
  savingRatio, 
  budgetPct,
  transactions,
  wallets,
  onNavigate,
  onOpenChat
}) {
  const [timeFilter, setTimeFilter] = useState('Bulan Ini');
  const [showNotifs, setShowNotifs] = useState(false);
  const getMonthYearString = (offsetMonths = 0) => {
    const d = new Date();
    d.setMonth(d.getMonth() + offsetMonths);
    return d.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' });
  };

  const currentMonthName = getMonthYearString(0);
  const prevMonthName = getMonthYearString(-1);
  const nextMonthName = getMonthYearString(1);

  const [selectedMonth, setSelectedMonth] = useState(currentMonthName);
  const [showMonthDropdown, setShowMonthDropdown] = useState(false);

  // Dynamic multipliers for month simulation
  let displayedSaldo = totalSaldo;
  let displayedPemasukan = totalPemasukan;
  let displayedPengeluaran = totalPengeluaran;
  let displayedSavingRatio = savingRatio;
  let displayedBudgetPct = budgetPct;
  let displayedTransactions = transactions;

  if (selectedMonth === prevMonthName) {
    displayedSaldo = Math.round(totalSaldo * 0.88);
    displayedPemasukan = Math.round(totalPemasukan * 0.92);
    displayedPengeluaran = Math.round(totalPengeluaran * 0.81);
    displayedSavingRatio = displayedPemasukan > 0 ? Math.round(((displayedPemasukan - displayedPengeluaran) / displayedPemasukan) * 100) : 0;
    displayedBudgetPct = budgetLimit > 0 ? (displayedPengeluaran / budgetLimit) : 0;
    
    // Map dates to previous month dynamically
    const currentMonthNum = String(new Date().getMonth() + 1).padStart(2, '0');
    const prevMonthNum = String(((new Date().getMonth() - 1 + 12) % 12) + 1).padStart(2, '0');
    displayedTransactions = transactions.map((t, idx) => ({
      ...t,
      date: t.date.replaceAll(`-${currentMonthNum}-`, `-${prevMonthNum}-`),
      amount: Math.round(t.amount * 0.85)
    }));
  } else if (selectedMonth === nextMonthName) {
    displayedSaldo = totalSaldo; 
    displayedPemasukan = 0;
    displayedPengeluaran = 0;
    displayedSavingRatio = 0;
    displayedBudgetPct = 0;
    displayedTransactions = [];
  }

  // Format IDR currency
  const formatIDR = (num) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: num % 1 !== 0 ? 2 : 0,
      maximumFractionDigits: 2
    }).format(num);
  };

  // Chart data based on selected filter
  const chartData = {
    '7 Hari Terakhir': [
      { name: 'Sen', Pemasukan: 0, Pengeluaran: 50000 },
      { name: 'Sel', Pemasukan: 1000000, Pengeluaran: 430000 },
      { name: 'Rab', Pemasukan: 0, Pengeluaran: 120000 },
      { name: 'Kam', Pemasukan: 0, Pengeluaran: 650000 },
      { name: 'Jum', Pemasukan: 2500000, Pengeluaran: 300000 },
      { name: 'Sab', Pemasukan: 0, Pengeluaran: 150000 },
      { name: 'Min', Pemasukan: 0, Pengeluaran: 80000 },
    ],
    '30 Hari Terakhir': [
      { name: 'Minggu 1', Pemasukan: 3500000, Pengeluaran: 1200000 },
      { name: 'Minggu 2', Pemasukan: 1200000, Pengeluaran: 950000 },
      { name: 'Minggu 3', Pemasukan: 800000, Pengeluaran: 1400000 },
      { name: 'Minggu 4', Pemasukan: 2000000, Pengeluaran: 600000 },
    ],
    'Bulan Ini': [
      { name: 'Tanggal 1-5', Pemasukan: 3500000, Pengeluaran: 800000 },
      { name: 'Tanggal 6-10', Pemasukan: 800000, Pengeluaran: 1200000 },
      { name: 'Tanggal 11-15', Pemasukan: 1500000, Pengeluaran: 500000 },
      { name: 'Tanggal 16-20', Pemasukan: 0, Pengeluaran: 950000 },
      { name: 'Tanggal 21-25', Pemasukan: 1000000, Pengeluaran: 400000 },
      { name: 'Tanggal 26-30', Pemasukan: 0, Pengeluaran: 300000 },
    ]
  };

  const activeData = chartData[timeFilter] || chartData['Bulan Ini'];

  // Status Keuangan Color & Label
  const getStatusLabel = () => {
    if (selectedMonth === nextMonthName) return { label: 'Belum Ada Transaksi', color: 'text-cuanly-textMuted border-cuanly-border bg-white/5' };
    if (displayedBudgetPct > 0.9) return { label: 'Defisit / Waspada', color: 'text-cuanly-red border-cuanly-red/20 bg-cuanly-red/10' };
    if (displayedBudgetPct > 0.7) return { label: 'Waspada', color: 'text-cuanly-yellow border-cuanly-yellow/20 bg-cuanly-yellow/10' };
    return { label: 'Sangat Sehat', color: 'text-cuanly-mint border-cuanly-mint/20 bg-cuanly-mint/10' };
  };
  const renderWalletLogo = (name, designType) => {
    const lowerName = name.toLowerCase();
    if (lowerName.includes('mandiri')) {
      return (
        <div className="w-8 h-8 rounded-lg bg-[#003d79] flex flex-col items-center justify-center overflow-hidden border border-white/5 shadow-inner">
          <span className="text-[7px] text-[#ffc72c] font-black tracking-wider uppercase leading-none select-none">mandırı</span>
          <div className="w-6 h-0.5 bg-[#ffc72c] rounded-full mt-0.5"></div>
        </div>
      );
    }
    if (lowerName.includes('gopay')) {
      return (
        <div className="w-8 h-8 rounded-lg bg-[#00aed6] flex flex-col items-center justify-center overflow-hidden border border-white/5 shadow-inner leading-none">
          <span className="text-[10px] font-black text-white italic tracking-tighter select-none">go<span className="font-bold not-italic">pay</span></span>
        </div>
      );
    }
    if (lowerName.includes('ovo')) {
      return (
        <div className="w-8 h-8 rounded-lg bg-[#4c2b85] flex items-center justify-center overflow-hidden border border-white/10 shadow-inner">
          <span className="text-[10px] font-black text-white tracking-widest pl-0.5 uppercase select-none">ovo</span>
        </div>
      );
    }
    if (lowerName.includes('cash') || lowerName.includes('tunai') || lowerName.includes('fisik')) {
      return (
        <div className="w-8 h-8 rounded-lg bg-[#10b981] flex items-center justify-center overflow-hidden border border-white/5 shadow-inner">
          <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <rect x="2" y="6" width="20" height="12" rx="2" />
            <circle cx="12" cy="12" r="3" />
            <path d="M6 12h.01M18 12h.01" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>
      );
    }
    return (
      <div className={`w-8 h-8 rounded-lg flex items-center justify-center font-bold text-xs text-white shadow-inner uppercase ${
        designType === 'blue' ? 'bg-blue-600' :
        designType === 'teal' ? 'bg-teal-600' :
        designType === 'purple' ? 'bg-purple-600' : 'bg-slate-600'
      }`}>
        {name.substring(0, 1)}
      </div>
    );
  };

  const status = getStatusLabel();

  return (
    <div className="flex-1 p-8 overflow-y-auto bg-cuanly-bg text-white">
      {/* Welcome Banner */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h2 className="text-2xl font-black tracking-tight">Selamat Datang di Cuanly Dashboard!</h2>
          <p className="text-sm text-cuanly-textMuted mt-1">Pantau, analisis, dan optimalkan kondisi keuangan Anda dibantu AI.</p>
        </div>

        <div className="flex items-center space-x-3">
          {/* Status Badge */}
          <div className={`px-4 py-2 rounded-xl text-xs font-bold border ${status.color}`}>
            Status: {status.label}
          </div>

          {/* Smart Notification Bell */}
          <div className="relative">
            <button 
              onClick={() => setShowNotifs(!showNotifs)}
              className="p-2 rounded-xl border border-cuanly-border bg-white/5 hover:bg-white/10 text-cuanly-violetLight relative transition-colors cursor-pointer"
            >
              <Bell size={16} />
              <span className="absolute top-1 right-1 w-1.5 h-1.5 bg-cuanly-red rounded-full"></span>
            </button>

            {showNotifs && (
              <div className="absolute right-0 mt-3 w-80 bg-cuanly-card border border-cuanly-border rounded-2xl p-4 shadow-2xl z-50 space-y-3">
                <div className="flex justify-between items-center border-b border-cuanly-border pb-2">
                  <span className="text-xs font-black text-white">Notifikasi Pintar</span>
                  <span className="text-[10px] text-cuanly-violetLight font-bold cursor-pointer hover:underline" onClick={() => setShowNotifs(false)}>Tutup</span>
                </div>
                <div className="space-y-3">
                  <div className="flex items-start space-x-2 text-xs p-2 rounded-lg bg-white/5">
                    <span className="text-cuanly-yellow mt-0.5">⚠️</span>
                    <div>
                      <p className="font-bold text-white">Batas Anggaran Makanan</p>
                      <p className="text-[10px] text-cuanly-textMuted mt-0.5">Anggaran Makan Siang sudah terpakai 85%. Pikir-pikir lagi sebelum jajan kopi ya!</p>
                    </div>
                  </div>
                  <div className="flex items-start space-x-2 text-xs p-2 rounded-lg bg-white/5">
                    <span className="text-cuanly-mint mt-0.5">📅</span>
                    <div>
                      <p className="font-bold text-white">Tagihan Spotify Premium</p>
                      <p className="text-[10px] text-cuanly-textMuted mt-0.5">Tagihan Spotify Rp 54.990 jatuh tempo besok (5 Juni). Saldo terpotong otomatis.</p>
                    </div>
                  </div>
                  <div className="flex items-start space-x-2 text-xs p-2 rounded-lg bg-white/5">
                    <span className="text-cuanly-violetLight mt-0.5">📊</span>
                    <div>
                      <p className="font-bold text-white">Rangkuman Mingguan</p>
                      <p className="text-[10px] text-cuanly-textMuted mt-0.5">Hebat! Pengeluaran mingguan Anda turun 12% dibanding minggu lalu.</p>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Month Selector Dropdown */}
          <div className="relative">
            <button 
              onClick={() => setShowMonthDropdown(!showMonthDropdown)}
              className="px-4 py-2 rounded-xl text-xs font-bold border border-cuanly-border bg-white/5 hover:bg-white/10 flex items-center space-x-2 transition-colors cursor-pointer"
            >
              <Calendar size={14} className="text-cuanly-violetLight" />
              <span>{selectedMonth}</span>
            </button>

            {showMonthDropdown && (
              <div className="absolute right-0 mt-2 w-40 bg-cuanly-card border border-cuanly-border rounded-xl shadow-2xl z-50 overflow-hidden">
                {[prevMonthName, currentMonthName, nextMonthName].map((m) => (
                  <button
                    key={m}
                    onClick={() => {
                      setSelectedMonth(m);
                      setShowMonthDropdown(false);
                    }}
                    className={`w-full text-left px-4 py-2.5 text-xs hover:bg-white/5 transition-colors block ${
                      selectedMonth === m ? 'text-cuanly-violetLight font-bold bg-white/5' : 'text-white'
                    }`}
                  >
                    {m} {m === currentMonthName ? '(Bulan Ini)' : ''}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {/* Total Saldo */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 transition-all duration-300 hover:-translate-y-1 hover:border-cuanly-violet/40 group relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-cuanly-violet/5 rounded-full blur-2xl group-hover:bg-cuanly-violet/10 transition-all duration-300"></div>
          <div className="flex justify-between items-start mb-4">
            <div className="p-3 rounded-xl bg-cuanly-violet/10 text-cuanly-violetLight">
              <Wallet size={20} />
            </div>
            <span className="text-[10px] font-bold text-cuanly-mint flex items-center space-x-1">
              <span>Aktif</span>
              <ArrowUpRight size={10} />
            </span>
          </div>
          <p className="text-xs text-cuanly-textMuted font-medium uppercase tracking-wider">Total Saldo</p>
          <h3 className="text-xl font-black mt-2 tracking-tight group-hover:text-cuanly-violetLight transition-colors duration-200">{formatIDR(displayedSaldo)}</h3>
        </div>

        {/* Pemasukan */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 transition-all duration-300 hover:-translate-y-1 hover:border-cuanly-mint/40 group relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-cuanly-mint/5 rounded-full blur-2xl group-hover:bg-cuanly-mint/10 transition-all duration-300"></div>
          <div className="flex justify-between items-start mb-4">
            <div className="p-3 rounded-xl bg-cuanly-mint/10 text-cuanly-mint">
              <TrendingUp size={20} />
            </div>
            <span className="text-[10px] font-bold text-cuanly-mint flex items-center space-x-1">
              <span>Gaji & Transfer</span>
            </span>
          </div>
          <p className="text-xs text-cuanly-textMuted font-medium uppercase tracking-wider">Pemasukan</p>
          <h3 className="text-xl font-black mt-2 tracking-tight">{formatIDR(displayedPemasukan)}</h3>
        </div>

        {/* Pengeluaran */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 transition-all duration-300 hover:-translate-y-1 hover:border-cuanly-coral/40 group relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-cuanly-coral/5 rounded-full blur-2xl group-hover:bg-cuanly-coral/10 transition-all duration-300"></div>
          <div className="flex justify-between items-start mb-4">
            <div className="p-3 rounded-xl bg-cuanly-coral/10 text-cuanly-coral">
              <TrendingDown size={20} />
            </div>
            <span className="text-[10px] font-bold text-cuanly-coral flex items-center space-x-1">
              <span>Bulan Ini</span>
            </span>
          </div>
          <p className="text-xs text-cuanly-textMuted font-medium uppercase tracking-wider">Pengeluaran</p>
          <h3 className="text-xl font-black mt-2 tracking-tight">{formatIDR(displayedPengeluaran)}</h3>
        </div>
 
        {/* Sisa Anggaran */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 transition-all duration-300 hover:-translate-y-1 hover:border-cuanly-violet/40 group relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-cuanly-violet/5 rounded-full blur-2xl group-hover:bg-cuanly-violet/10 transition-all duration-300"></div>
          <div className="flex justify-between items-start mb-4">
            <div className="p-3 rounded-xl bg-cuanly-violet/10 text-cuanly-violetLight">
              <PieChart size={20} />
            </div>
            <span className="text-[10px] font-bold text-cuanly-textMuted">
              Limit: {formatIDR(budgetLimit)}
            </span>
          </div>
          <p className="text-xs text-cuanly-textMuted font-medium uppercase tracking-wider">Sisa Anggaran</p>
          <h3 className="text-xl font-black mt-2 tracking-tight">{formatIDR(Math.max(0, budgetLimit - displayedPengeluaran))}</h3>
        </div>
      </div>

      {/* Main Grid: Graph + AI Insight */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
        {/* Interactive Trend Chart */}
        <div className="lg:col-span-2 bg-cuanly-card border border-cuanly-border rounded-2xl p-6">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h3 className="text-base font-bold">Tren Aliran Dana</h3>
              <p className="text-xs text-cuanly-textMuted mt-0.5">Perbandingan pemasukan vs pengeluaran terkini</p>
            </div>
            {/* Period Filters */}
            <div className="bg-white/5 border border-cuanly-border p-1 rounded-xl flex space-x-1">
              {['7 Hari Terakhir', '30 Hari Terakhir', 'Bulan Ini'].map((filter) => (
                <button
                  key={filter}
                  onClick={() => setTimeFilter(filter)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all duration-200 ${
                    timeFilter === filter 
                      ? 'bg-cuanly-violet text-white shadow' 
                      : 'text-cuanly-textMuted hover:text-white'
                  }`}
                >
                  {filter}
                </button>
              ))}
            </div>
          </div>

          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={activeData}>
                <defs>
                  <linearGradient id="colorPemasukan" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#1D9E75" stopOpacity={0.2}/>
                    <stop offset="95%" stopColor="#1D9E75" stopOpacity={0.0}/>
                  </linearGradient>
                  <linearGradient id="colorPengeluaran" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#D85A30" stopOpacity={0.2}/>
                    <stop offset="95%" stopColor="#D85A30" stopOpacity={0.0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis dataKey="name" stroke="#8B8A88" fontSize={11} tickLine={false} />
                <YAxis stroke="#8B8A88" fontSize={11} tickLine={false} axisLine={false} tickFormatter={(v) => `Rp ${v/1000}k`} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1C1C24', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '12px' }}
                  labelStyle={{ fontWeight: 'bold', color: '#fff' }}
                  itemStyle={{ fontSize: '12px' }}
                />
                <Area type="monotone" dataKey="Pemasukan" stroke="#1D9E75" strokeWidth={2} fillOpacity={1} fill="url(#colorPemasukan)" />
                <Area type="monotone" dataKey="Pengeluaran" stroke="#D85A30" strokeWidth={2} fillOpacity={1} fill="url(#colorPengeluaran)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* AI Insight of the Day */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 flex flex-col justify-between relative overflow-hidden group">
          {/* Subtle glowing ring background */}
          <div className="absolute -top-16 -right-16 w-36 h-36 bg-cuanly-violet/10 rounded-full blur-3xl group-hover:bg-cuanly-violet/20 transition-all duration-300"></div>

          <div>
            <div className="flex items-center space-x-2 text-cuanly-violetLight mb-4">
              <Sparkles size={20} className="animate-pulse" />
              <h3 className="text-base font-bold text-white">AI Insight of the Day</h3>
            </div>
            
            <p className="text-sm text-gray-200 leading-relaxed">
              "Kesehatan finansial Anda tergolong <strong className="text-cuanly-mint">{selectedMonth === 'Juli 2026' ? 'Belum Ada Transaksi' : 'Sangat Sehat'}</strong>. Rasio menabung Anda berada di angka <strong className="text-cuanly-violetLight">{displayedSavingRatio}%</strong>, melewati target standar 30%."
            </p>
            
            <div className="mt-4 p-4 bg-white/5 rounded-xl border border-white/5 text-xs text-cuanly-textMuted leading-relaxed space-y-3">
              <div>
                💡 <strong>Rekomendasi Cerdas:</strong> {selectedMonth === 'Juli 2026' ? 'Belum ada data pengeluaran untuk dianalisis bulan ini.' : 'Belanja makanan Anda naik 14% dibanding minggu lalu. Disarankan untuk membatasi pengeluaran akhir pekan.'}
              </div>
              <hr className="border-white/5" />
              <div className="flex justify-between items-center text-white">
                <div>
                  <span className="text-[10px] text-cuanly-textMuted block uppercase font-bold tracking-wider">Prediksi Saldo Akhir Bulan</span>
                  <span className="font-black text-sm">{formatIDR(displayedSaldo - (selectedMonth === 'Juli 2026' ? 0 : 450000))}</span>
                </div>
                <span className="px-2.5 py-1 rounded-full bg-cuanly-mint/10 text-cuanly-mint font-bold text-[9px] whitespace-nowrap flex-shrink-0">💡 Pace Aman</span>
              </div>
            </div>
          </div>

          <div className="mt-6">
            <button 
              onClick={onOpenChat}
              className="w-full flex items-center justify-center space-x-2 py-3 rounded-xl text-xs font-bold bg-gradient-to-r from-cuanly-violet to-cuanly-violetLight text-white shadow-lg shadow-cuanly-violet/30 hover:opacity-90 transition-all duration-200"
            >
              <span>Konsultasi Cuanly</span>
              <ArrowUpRight size={14} />
            </button>
          </div>
        </div>
      </div>

      {/* Grid: Financial Goals & Auto Subscription Detector */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        {/* Financial Goals */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-base font-bold text-white flex items-center space-x-2">
              <span className="text-cuanly-violetLight">🎯</span>
              <span>Target Menabung (Goals)</span>
            </h3>
            <span className="text-[10px] font-bold text-cuanly-textMuted">2 Target Aktif</span>
          </div>

          <div className="space-y-5">
            {/* Goal 1 */}
            <div className="p-4 bg-white/5 border border-white/5 rounded-xl">
              <div className="flex justify-between items-center mb-2">
                <span className="text-xs font-bold text-white">💻 Beli Laptop Baru</span>
                <span className="text-[10px] text-cuanly-textMuted">{formatIDR(4500000)} / {formatIDR(7500000)}</span>
              </div>
              <div className="w-full h-2 bg-white/5 rounded-full overflow-hidden mb-2">
                <div className="h-full bg-cuanly-violet rounded-full" style={{ width: '60%' }}></div>
              </div>
              <p className="text-[10px] text-cuanly-textMuted font-bold">Tercapai 60% — Butuh Rp 500.000 lagi bulan ini untuk tetap sesuai jadwal target.</p>
            </div>

            {/* Goal 2 */}
            <div className="p-4 bg-white/5 border border-white/5 rounded-xl">
              <div className="flex justify-between items-center mb-2">
                <span className="text-xs font-bold text-white">🛡️ Dana Darurat 2026</span>
                <span className="text-[10px] text-cuanly-textMuted">{formatIDR(1500000)} / {formatIDR(3000000)}</span>
              </div>
              <div className="w-full h-2 bg-white/5 rounded-full overflow-hidden mb-2">
                <div className="h-full bg-cuanly-mint rounded-full" style={{ width: '50%' }}></div>
              </div>
              <p className="text-[10px] text-cuanly-textMuted font-bold">Tercapai 50% — Dana tersimpan aman di dompet khusus cadangan.</p>
            </div>
          </div>
        </div>

        {/* Subscription Auto Detector */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-base font-bold text-white flex items-center space-x-2">
              <span className="text-cuanly-coral">💳</span>
              <span>Deteksi Langganan Otomatis</span>
            </h3>
            <span className="text-[10px] font-bold text-cuanly-textMuted">2 Layanan Terdaftar</span>
          </div>

          <div className="space-y-4">
            <div className="flex justify-between items-center p-3 rounded-xl bg-white/5 border border-white/5">
              <div>
                <h4 className="text-xs font-bold text-white">Spotify Premium</h4>
                <p className="text-[10px] text-cuanly-textMuted">Rp 54.990 / bulan • Terdebit otomatis</p>
              </div>
              <span className="px-2.5 py-1 rounded-lg bg-cuanly-mint/10 text-cuanly-mint text-[9px] font-bold">Sering digunakan (Aman)</span>
            </div>

            <div className="flex justify-between items-center p-3 rounded-xl bg-white/5 border border-white/5 relative overflow-hidden group">
              <div>
                <h4 className="text-xs font-bold text-white">Netflix Premium</h4>
                <p className="text-[10px] text-cuanly-textMuted">Rp 186.000 / bulan • Terdebit otomatis</p>
              </div>
              <div className="text-right">
                <span className="px-2.5 py-1 rounded-lg bg-cuanly-red/10 text-cuanly-red text-[9px] font-bold">Jarang digunakan</span>
                <p className="text-[9px] text-cuanly-yellow font-bold mt-1.5">💡 Rekomendasi: Downgrade!</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Grid: Wallets + Recent transactions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Wallet Balances list */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-base font-bold">Dompet Aktif</h3>
            <button 
              onClick={() => onNavigate('settings')}
              className="text-xs font-bold text-cuanly-violetLight hover:underline"
            >
              Kelola
            </button>
          </div>

          <div className="space-y-4">
            {wallets.length === 0 ? (
              <p className="text-xs text-cuanly-textMuted text-center py-6">Belum ada dompet.</p>
            ) : (
              wallets.map((wallet, idx) => (
                <div key={idx} className="flex justify-between items-center p-3 rounded-xl bg-white/5 border border-white/5 hover:border-cuanly-border transition-colors duration-200">
                  <div className="flex items-center space-x-3">
                    {renderWalletLogo(wallet.name, wallet.designType)}
                    <div>
                      <h4 className="text-xs font-bold text-white">{wallet.name}</h4>
                      <p className="text-[10px] text-cuanly-textMuted">{wallet.cardNumber}</p>
                    </div>
                  </div>
                  <span className="text-xs font-black">{formatIDR(wallet.balance)}</span>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Recent Transactions List */}
        <div className="lg:col-span-2 bg-cuanly-card border border-cuanly-border rounded-2xl p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-base font-bold">Aktivitas Terakhir</h3>
            <button 
              onClick={() => onNavigate('analytics')}
              className="text-xs font-bold text-cuanly-violetLight hover:underline"
            >
              Lihat Detail
            </button>
          </div>

          <div className="space-y-3">
            {displayedTransactions.length === 0 ? (
              <p className="text-xs text-cuanly-textMuted text-center py-6">Belum ada transaksi.</p>
            ) : (
              displayedTransactions.slice(0, 4).map((tx, idx) => (
                <div key={idx} className="flex justify-between items-center p-3 rounded-xl bg-white/5 border border-white/5 hover:bg-white/10 transition-colors duration-200">
                  <div className="flex items-center space-x-3">
                    <div className={`p-2 rounded-lg ${tx.isExpense ? 'bg-cuanly-coral/10 text-cuanly-coral' : 'bg-cuanly-mint/10 text-cuanly-mint'}`}>
                      {tx.isExpense ? <TrendingDown size={14} /> : <TrendingUp size={14} />}
                    </div>
                    <div>
                      <h4 className="text-xs font-bold text-white">{tx.title}</h4>
                      <p className="text-[10px] text-cuanly-textMuted">{tx.category} • {tx.wallet}</p>
                    </div>
                  </div>
                  <span className={`text-xs font-black ${tx.isExpense ? 'text-white' : 'text-cuanly-mint'}`}>
                    {tx.isExpense ? '-' : '+'} {formatIDR(tx.amount)}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
