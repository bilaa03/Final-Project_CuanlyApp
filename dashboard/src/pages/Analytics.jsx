import React, { useState, useMemo } from 'react';
import { 
  Search, 
  ChevronDown, 
  ChevronUp, 
  Filter, 
  TrendingDown, 
  TrendingUp,
  Download,
  Info
} from 'lucide-react';
import { 
  PieChart, 
  Pie, 
  Cell, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  Legend, 
  ResponsiveContainer 
} from 'recharts';

export function Analytics({ transactions, budgetLimit }) {
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('All');
  const [typeFilter, setTypeFilter] = useState('All'); // All, Expense, Income
  const [sortField, setSortField] = useState('date');
  const [sortOrder, setSortOrder] = useState('desc');
  const [drillDownCategory, setDrillDownCategory] = useState(null);

  const handleExportCSV = () => {
    if (transactions.length === 0) {
      alert('Tidak ada data transaksi untuk diekspor!');
      return;
    }
    const headers = ['Tanggal', 'Deskripsi / Judul', 'Kategori', 'Dompet / Metode', 'Tipe', 'Nominal (IDR)'];
    const rows = transactions.map(t => [
      t.date,
      t.title,
      t.category,
      t.wallet,
      t.isExpense ? 'Pengeluaran' : 'Pemasukan',
      t.amount
    ]);
    const csvContent = "data:text/csv;charset=utf-8,\ufeff" 
      + [headers, ...rows].map(e => e.map(val => `"${String(val).replace(/"/g, '""')}"`).join(',')).join('\n');
      
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `Cuanly_Laporan_Transaksi_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const formatIDR = (num) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: num % 1 !== 0 ? 2 : 0,
      maximumFractionDigits: 2
    }).format(num);
  };

  // Group transactions by category for Donut chart
  const categoryTotals = useMemo(() => {
    const expenses = transactions.filter(t => t.isExpense);
    const totals = {};
    expenses.forEach(t => {
      totals[t.category] = (totals[t.category] || 0) + t.amount;
    });
    return Object.entries(totals).map(([name, value]) => ({ name, value }));
  }, [transactions]);

  const COLORS = ['#534AB7', '#7F77DD', '#1D9E75', '#D85A30', '#EF9F27', '#E24B4A'];

  // Periodic comparison data (Mock)
  const comparisonData = [
    { name: 'Makanan', 'Bulan Lalu': 500000, 'Bulan Ini': 650000 },
    { name: 'Transport', 'Bulan Lalu': 180000, 'Bulan Ini': 320000 },
    { name: 'Belanja', 'Bulan Lalu': 600000, 'Bulan Ini': 430000 },
    { name: 'Hiburan', 'Bulan Lalu': 450000, 'Bulan Ini': 90000 },
    { name: 'Lainnya', 'Bulan Lalu': 150000, 'Bulan Ini': 210000 },
  ];

  // Table filtering and sorting
  const filteredAndSortedTransactions = useMemo(() => {
    let result = [...transactions];

    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      result = result.filter(
        t => t.title.toLowerCase().includes(term) || t.wallet.toLowerCase().includes(term)
      );
    }

    if (categoryFilter !== 'All') {
      result = result.filter(t => t.category === categoryFilter);
    }

    if (typeFilter !== 'All') {
      const isExpense = typeFilter === 'Expense';
      result = result.filter(t => t.isExpense === isExpense);
    }

    result.sort((a, b) => {
      let aVal = a[sortField];
      let bVal = b[sortField];

      if (sortField === 'date') {
        aVal = new Date(a.date).getTime();
        bVal = new Date(b.date).getTime();
      }

      if (aVal < bVal) return sortOrder === 'asc' ? -1 : 1;
      if (aVal > bVal) return sortOrder === 'asc' ? 1 : -1;
      return 0;
    });

    return result;
  }, [transactions, searchTerm, categoryFilter, typeFilter, sortField, sortOrder]);

  const handleSort = (field) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('desc');
    }
  };

  const categoriesList = useMemo(() => {
    return ['All', ...new Set(transactions.map(t => t.category))];
  }, [transactions]);

  // Drilldown list details
  const drillDownDetails = useMemo(() => {
    if (!drillDownCategory) return [];
    return transactions.filter(t => t.category === drillDownCategory && t.isExpense);
  }, [transactions, drillDownCategory]);

  return (
    <div className="flex-1 p-8 overflow-y-auto bg-cuanly-bg text-cuanly-textDark">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h2 className="text-2xl font-black tracking-tight">Analitik Finansial</h2>
          <p className="text-sm text-cuanly-textMuted mt-1">Laporan mendalam pola pengeluaran dan pemasukan Anda.</p>
        </div>
        <button 
          onClick={handleExportCSV}
          className="flex items-center space-x-2 px-4 py-2.5 rounded-xl text-xs font-bold bg-white border border-slate-200 hover:bg-slate-50 text-cuanly-textDark transition-colors duration-200 cursor-pointer"
        >
          <Download size={14} className="text-cuanly-mint" />
          <span>Ekspor CSV</span>
        </button>
      </div>

      {/* Main Grid: Pie Chart + Period Comparison */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        {/* Pie Chart / Donut drill down */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 shadow-sm shadow-slate-100">
          <h3 className="text-base font-bold text-cuanly-textDark mb-1">Distribusi Pengeluaran</h3>
          <p className="text-xs text-cuanly-textMuted mb-6">Klik kategori grafik untuk melihat rincian transaksi</p>

          <div className="flex flex-col sm:flex-row items-center justify-around h-60">
            {categoryTotals.length === 0 ? (
              <p className="text-xs text-cuanly-textMuted">Belum ada pengeluaran dicatat.</p>
            ) : (
              <>
                <div className="w-48 h-48">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={categoryTotals}
                        innerRadius={60}
                        outerRadius={80}
                        paddingAngle={4}
                        dataKey="value"
                        onClick={(data) => setDrillDownCategory(data.name)}
                        className="cursor-pointer focus:outline-none"
                      >
                        {categoryTotals.map((entry, index) => (
                          <Cell 
                            key={`cell-${index}`} 
                            fill={COLORS[index % COLORS.length]} 
                            stroke={drillDownCategory === entry.name ? '#0f172a' : 'none'}
                            strokeWidth={2}
                          />
                        ))}
                      </Pie>
                      <Tooltip formatter={(v) => formatIDR(v)} />
                    </PieChart>
                  </ResponsiveContainer>
                </div>

                {/* Legend list */}
                <div className="space-y-2 mt-4 sm:mt-0">
                  {categoryTotals.map((entry, idx) => (
                    <button
                      key={idx}
                      onClick={() => setDrillDownCategory(entry.name)}
                      className={`flex items-center space-x-2 text-xs font-bold px-3 py-1.5 rounded-lg border transition-all duration-200 ${
                        drillDownCategory === entry.name 
                          ? 'bg-slate-100 border-slate-200 text-cuanly-textDark' 
                          : 'border-transparent text-slate-600 hover:bg-slate-50'
                      }`}
                    >
                      <span className="w-3 h-3 rounded-full" style={{ backgroundColor: COLORS[idx % COLORS.length] }}></span>
                      <span className="text-slate-600">{entry.name}:</span>
                      <span>{formatIDR(entry.value)}</span>
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>

          {/* Drilldown details wrapper */}
          {drillDownCategory && (
            <div className="mt-6 p-4 bg-slate-50 rounded-xl border border-slate-200/50 animate-fadeIn">
              <div className="flex justify-between items-center mb-3">
                <h4 className="text-xs font-bold text-cuanly-violet uppercase tracking-wider">Detail Kategori: {drillDownCategory}</h4>
                <button 
                  onClick={() => setDrillDownCategory(null)}
                  className="text-[10px] font-bold text-cuanly-textMuted hover:text-cuanly-textDark"
                >
                  Tutup Rincian
                </button>
              </div>
              <div className="space-y-2 max-h-36 overflow-y-auto">
                {drillDownDetails.length === 0 ? (
                  <p className="text-[11px] text-cuanly-textMuted">Tidak ada pengeluaran di kategori ini.</p>
                ) : (
                  drillDownDetails.map((tx, idx) => (
                    <div key={idx} className="flex justify-between items-center text-xs py-1.5 border-b border-slate-200/50 last:border-0">
                      <span className="text-cuanly-textDark font-medium">{tx.title}</span>
                      <span className="font-bold text-cuanly-coral">{formatIDR(tx.amount)}</span>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}
        </div>

        {/* Period Comparison Chart */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 shadow-sm shadow-slate-100">
          <h3 className="text-base font-bold text-cuanly-textDark mb-1">Perbandingan Antar Periode</h3>
          <p className="text-xs text-cuanly-textMuted mb-6">Bulan Lalu vs Bulan Ini per kategori pengeluaran</p>

          <div className="h-60">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={comparisonData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="name" stroke="#64748b" fontSize={11} tickLine={false} />
                <YAxis stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} tickFormatter={(v) => `Rp ${v/1000}k`} />
                <Tooltip formatter={(v) => formatIDR(v)} />
                <Legend wrapperStyle={{ fontSize: '11px', paddingTop: '10px' }} />
                <Bar dataKey="Bulan Lalu" fill="#818cf8" radius={[4, 4, 0, 0]} />
                <Bar dataKey="Bulan Ini" fill="#059669" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Transaction Table Section */}
      <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 shadow-sm shadow-slate-100">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
          <div>
            <h3 className="text-base font-bold text-cuanly-textDark">Riwayat Transaksi</h3>
            <p className="text-xs text-cuanly-textMuted mt-0.5">Daftar transaksi terperinci yang dicatat sistem</p>
          </div>

          {/* Search, Filter, Sort Controls */}
          <div className="flex flex-wrap items-center gap-3 w-full sm:w-auto">
            {/* Search Input */}
            <div className="relative flex-1 sm:flex-none">
              <Search size={14} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-cuanly-textMuted" />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Cari transaksi..."
                className="w-full sm:w-48 bg-slate-50 border border-slate-200 rounded-xl pl-9 pr-4 py-2 text-xs focus:border-cuanly-violet focus:outline-none text-cuanly-textDark transition-colors duration-200"
              />
            </div>

            {/* Category Filter */}
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs text-cuanly-textDark focus:outline-none focus:border-cuanly-violet cursor-pointer"
            >
              <option value="All">Kategori: Semua</option>
              {categoriesList.filter(c => c !== 'All').map((cat) => (
                <option key={cat} value={cat}>{cat}</option>
              ))}
            </select>

            {/* Type Filter */}
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs text-cuanly-textDark focus:outline-none focus:border-cuanly-violet cursor-pointer"
            >
              <option value="All">Semua Transaksi</option>
              <option value="Expense">Pengeluaran</option>
              <option value="Income">Pemasukan</option>
            </select>
          </div>
        </div>

        {/* Responsive Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-cuanly-border text-cuanly-textMuted text-xs font-bold uppercase tracking-wider">
                <th className="py-3 px-4">
                  <button onClick={() => handleSort('title')} className="flex items-center space-x-1 hover:text-cuanly-textDark transition-colors duration-150">
                    <span>Transaksi</span>
                    {sortField === 'title' && (sortOrder === 'asc' ? <ChevronUp size={12} /> : <ChevronDown size={12} />)}
                  </button>
                </th>
                <th className="py-3 px-4">Kategori</th>
                <th className="py-3 px-4">
                  <button onClick={() => handleSort('date')} className="flex items-center space-x-1 hover:text-cuanly-textDark transition-colors duration-150">
                    <span>Tanggal</span>
                    {sortField === 'date' && (sortOrder === 'asc' ? <ChevronUp size={12} /> : <ChevronDown size={12} />)}
                  </button>
                </th>
                <th className="py-3 px-4">Metode/Dompet</th>
                <th className="py-3 px-4 text-right">
                  <button onClick={() => handleSort('amount')} className="flex items-center space-x-1 hover:text-cuanly-textDark transition-colors duration-150 ml-auto">
                    <span>Jumlah</span>
                    {sortField === 'amount' && (sortOrder === 'asc' ? <ChevronUp size={12} /> : <ChevronDown size={12} />)}
                  </button>
                </th>
              </tr>
            </thead>
            <tbody>
              {filteredAndSortedTransactions.length === 0 ? (
                <tr>
                  <td colSpan="5" className="py-12 text-center text-xs text-cuanly-textMuted">
                    Tidak ditemukan data transaksi yang sesuai filter.
                  </td>
                </tr>
              ) : (
                filteredAndSortedTransactions.map((tx) => (
                  <tr key={tx.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors duration-150 text-xs">
                    <td className="py-4 px-4 font-semibold flex items-center space-x-3 text-cuanly-textDark">
                      <div className={`p-2 rounded-lg ${tx.isExpense ? 'bg-cuanly-coral/10 text-cuanly-coral' : 'bg-cuanly-mint/10 text-cuanly-mint'}`}>
                        {tx.isExpense ? <TrendingDown size={14} /> : <TrendingUp size={14} />}
                      </div>
                      <span>{tx.title}</span>
                    </td>
                    <td className="py-4 px-4 text-cuanly-textDark">
                      <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-slate-50 border border-slate-200">
                        {tx.category}
                      </span>
                    </td>
                    <td className="py-4 px-4 text-cuanly-textMuted">
                      {new Date(tx.date).toLocaleDateString('id-ID', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </td>
                    <td className="py-4 px-4 font-semibold text-cuanly-textDark">{tx.wallet}</td>
                    <td className={`py-4 px-4 text-right font-black ${tx.isExpense ? 'text-cuanly-textDark' : 'text-cuanly-mint'}`}>
                      {tx.isExpense ? '-' : '+'} {formatIDR(tx.amount)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
