import React, { useState } from 'react';
import { 
  Check, 
  X, 
  FileText, 
  Download, 
  ShieldAlert, 
  Award,
  Users,
  Eye,
  FileCheck
} from 'lucide-react';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  Cell 
} from 'recharts';

export function B2BFinance() {
  const [claims, setClaims] = useState([
    { id: 1, name: 'Andi Saputra', department: 'Engineering', title: 'AWS Cloud Hosting', amount: 1500000, date: '2026-06-28', status: 'pending', description: 'Biaya langganan server AWS dev environment.' },
    { id: 2, name: 'Siti Rahma', department: 'Sales', title: 'Client Lunch - Mandiri', amount: 450000, date: '2026-06-27', status: 'approved', description: 'Makan siang bisnis bersama perwakilan IT Bank Mandiri.' },
    { id: 3, name: 'Rian Hidayat', department: 'Marketing', title: 'Facebook Ads Campaign', amount: 2500000, date: '2026-06-25', status: 'pending', description: 'Iklan promosi peluncuran fitur baru Cuanly B2B.' },
    { id: 4, name: 'Diana Putri', department: 'HR', title: 'Software Canva Pro', amount: 350000, date: '2026-06-24', status: 'rejected', description: 'Langganan Canva untuk rekrutmen desain poster lowongan.' },
  ]);

  const [activePreviewClaim, setActivePreviewClaim] = useState(null);
  const [exportMode, setExportMode] = useState(null); // 'pdf' or 'excel' or null

  // Submit Claim Form states
  const [newName, setNewName] = useState('');
  const [newDept, setNewDept] = useState('Engineering');
  const [newTitle, setNewTitle] = useState('');
  const [newAmount, setNewAmount] = useState('');
  const [newDate, setNewDate] = useState(new Date().toISOString().split('T')[0]);
  const [newDesc, setNewDesc] = useState('');

  const handleAddClaim = (e) => {
    e.preventDefault();
    if (!newName.trim() || !newTitle.trim() || !newAmount) {
      alert('Mohon isi nama, judul klaim, dan jumlah uang pengajuan!');
      return;
    }
    const newClaim = {
      id: Date.now(),
      name: newName.trim(),
      department: newDept,
      title: newTitle.trim(),
      amount: Number(newAmount),
      date: newDate || new Date().toISOString().split('T')[0],
      status: 'pending',
      description: newDesc.trim() || 'Tidak ada keterangan tambahan.'
    };
    setClaims(prev => [newClaim, ...prev]);
    setNewName('');
    setNewTitle('');
    setNewAmount('');
    setNewDate(new Date().toISOString().split('T')[0]);
    setNewDesc('');
    alert('Pengajuan reimbursement Anda berhasil dikirim ke antrean approval!');
  };

  const handleDownload = () => {
    if (exportMode === 'excel') {
      const csvContent = "data:text/csv;charset=utf-8," 
        + [
            ['CUANLY B2B FINANCIAL REPORT'],
            ['Periode: Mei - Juni 2026'],
            ['Tanggal Cetak: ' + new Date().toLocaleString()],
            [],
            ['Departemen', 'Anggaran (Budget)', 'Realisasi', 'Status Efisiensi'],
            ['Engineering', 'Rp 50.000.000', 'Rp 48.000.000', '96% (Aman)'],
            ['Marketing', 'Rp 60.000.000', 'Rp 55.000.000', '92% (Aman)'],
            ['Sales', 'Rp 35.000.000', 'Rp 32.000.000', '91% (Aman)'],
            ['HR', 'Rp 15.000.000', 'Rp 12.000.000', '80% (Aman)'],
            [],
            ['Total Pengeluaran Grup: Rp 147.000.000']
          ].map(e => e.map(val => `"${val}"`).join(',')).join('\n');
          
      const encodedUri = encodeURI(csvContent);
      const link = document.createElement("a");
      link.setAttribute("href", encodedUri);
      link.setAttribute("download", "Cuanly_B2B_Financial_Report.csv");
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    } else {
      // PDF/Text mode
      const txtContent = "data:text/plain;charset=utf-8," 
        + [
            '==================================================',
            '            CUANLY B2B FINANCIAL REPORT           ',
            '==================================================',
            'Tanggal Cetak: ' + new Date().toLocaleString(),
            'Periode      : Mei - Juni 2026',
            'Penyusun     : Finance Manager Hub',
            '--------------------------------------------------',
            '',
            'RINCIAN ANGGARAN DEPARTEMEN:',
            '1. Engineering',
            '   - Budget   : Rp 50.000.000',
            '   - Realisasi: Rp 48.000.000',
            '   - Efisiensi: 96% (Aman)',
            '2. Marketing',
            '   - Budget   : Rp 60.000.000',
            '   - Realisasi: Rp 55.000.000',
            '   - Efisiensi: 92% (Aman)',
            '3. Sales',
            '   - Budget   : Rp 35.000.000',
            '   - Realisasi: Rp 32.000.000',
            '   - Efisiensi: 91% (Aman)',
            '4. HR',
            '   - Budget   : Rp 15.000.000',
            '   - Realisasi: Rp 12.000.000',
            '   - Efisiensi: 80% (Aman)',
            '--------------------------------------------------',
            'Total Pengeluaran Grup: Rp 147.000.000',
            '=================================================='
          ].map(row => encodeURIComponent(row)).join('\n');
          
      const link = document.createElement("a");
      link.setAttribute("href", txtContent);
      link.setAttribute("download", "Cuanly_B2B_Financial_Report.txt");
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
    setExportMode(null);
  };

  const formatIDR = (num) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: num % 1 !== 0 ? 2 : 0,
      maximumFractionDigits: 2
    }).format(num);
  };

  const handleApprove = (id) => {
    setClaims(claims.map(c => c.id === id ? { ...c, status: 'approved' } : c));
    if (activePreviewClaim?.id === id) {
      setActivePreviewClaim({ ...activePreviewClaim, status: 'approved' });
    }
  };

  const handleReject = (id) => {
    setClaims(claims.map(c => c.id === id ? { ...c, status: 'rejected' } : c));
    if (activePreviewClaim?.id === id) {
      setActivePreviewClaim({ ...activePreviewClaim, status: 'rejected' });
    }
  };

  // Department aggregate data
  const deptData = [
    { name: 'Engineering', Pengeluaran: 48000000, color: '#4f46e5' },
    { name: 'Sales', Pengeluaran: 32000000, color: '#818cf8' },
    { name: 'Marketing', Pengeluaran: 55000000, color: '#ea580c' },
    { name: 'HR', Pengeluaran: 12000000, color: '#f59e0b' },
  ];

  // Leaderboard B2B saving challenge (Score = budget left percentage)
  const leaderboard = [
    { rank: 1, name: 'HR Department', score: '94%', saved: 8500000, progress: 94 },
    { rank: 2, name: 'Sales Department', score: '88%', saved: 12000000, progress: 88 },
    { rank: 3, name: 'Engineering Department', score: '82%', saved: 25000000, progress: 82 },
    { rank: 4, name: 'Marketing Department', score: '67%', saved: 5000000, progress: 67 },
  ];

  return (
    <div className="flex-1 p-8 overflow-y-auto bg-cuanly-bg text-cuanly-textDark">
      {/* Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h2 className="text-2xl font-black tracking-tight">Portal Bisnis (B2B Mode)</h2>
          <p className="text-sm text-cuanly-textMuted mt-1">Konsolidasi anggaran, pengeluaran departemen, dan alur klaim karyawan.</p>
        </div>
        <div className="flex space-x-3">
          <button 
            onClick={() => setExportMode('pdf')}
            className="flex items-center space-x-2 px-4 py-2.5 rounded-xl text-xs font-bold bg-white text-cuanly-violet border border-slate-200 hover:bg-slate-50 transition-all duration-200"
          >
            <FileText size={14} />
            <span>Preview Laporan PDF</span>
          </button>
          <button 
            onClick={() => setExportMode('excel')}
            className="flex items-center space-x-2 px-4 py-2.5 rounded-xl text-xs font-bold bg-white text-cuanly-mint border border-slate-200 hover:bg-slate-50 transition-all duration-200"
          >
            <Download size={14} />
            <span>Preview Excel</span>
          </button>
        </div>
      </div>

      {/* Export Report Preview Drawer / Overlay */}
      {exportMode && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-cuanly-card border border-cuanly-border rounded-2xl max-w-2xl w-full p-6 shadow-xl shadow-slate-200 relative overflow-hidden animate-scaleUp">
            <button 
              onClick={() => setExportMode(null)}
              className="absolute top-4 right-4 text-cuanly-textMuted hover:text-cuanly-textDark"
            >
              <X size={20} />
            </button>
            <div className="flex items-center space-x-3 mb-6">
              <div className="p-3 rounded-xl bg-cuanly-violet/10 text-cuanly-violet">
                <FileCheck size={24} />
              </div>
              <div>
                <h3 className="text-base font-bold text-cuanly-textDark">Pratinjau Ekspor Laporan ({exportMode.toUpperCase()})</h3>
                <p className="text-xs text-cuanly-textMuted">Laporan Konsolidasi Finansial - Q2 2026</p>
              </div>
            </div>

            {/* Document mock preview paper */}
            <div className="bg-white text-slate-800 p-6 rounded-xl border border-gray-200 shadow-inner text-xs font-mono mb-6 max-h-80 overflow-y-auto">
              <div className="text-center border-b border-gray-300 pb-4 mb-4">
                <h4 className="font-bold text-sm tracking-tight">CUANLY BUSINESS REPORT</h4>
                <p className="text-[10px] text-gray-500">Gedung AI Hub Lt 5, Jakarta Selatan</p>
              </div>
              
              <div className="space-y-2 mb-4">
                <p><strong>Tanggal Cetak:</strong> 2026-07-04 19:54</p>
                <p><strong>Periode:</strong> Mei - Juni 2026</p>
                <p><strong>Penyusun:</strong> Finance Manager Hub</p>
              </div>

              <table className="w-full text-left border-collapse text-[10px] mb-4">
                <thead>
                  <tr className="border-b border-gray-300 bg-gray-50 font-bold">
                    <th className="p-2">Departemen</th>
                    <th className="p-2">Anggaran (Budget)</th>
                    <th className="p-2">Realisasi</th>
                    <th className="p-2 text-right">Efisiensi</th>
                  </tr>
                </thead>
                <tbody>
                  <tr className="border-b border-gray-200">
                    <td className="p-2">Engineering</td>
                    <td className="p-2">Rp 50.000.000</td>
                    <td className="p-2">Rp 48.000.000</td>
                    <td className="p-2 text-right text-green-600">+96% (Aman)</td>
                  </tr>
                  <tr className="border-b border-gray-200">
                    <td className="p-2">Marketing</td>
                    <td className="p-2">Rp 60.000.000</td>
                    <td className="p-2">Rp 55.000.000</td>
                    <td className="p-2 text-right text-green-600">+92% (Aman)</td>
                  </tr>
                  <tr className="border-b border-gray-200">
                    <td className="p-2">Sales</td>
                    <td className="p-2">Rp 35.000.000</td>
                    <td className="p-2">Rp 32.000.000</td>
                    <td className="p-2 text-right text-green-600">+91% (Aman)</td>
                  </tr>
                </tbody>
              </table>

              <div className="text-right pt-4 border-t border-gray-300 font-bold text-[11px]">
                Total Pengeluaran Grup: Rp 135.000.000
              </div>
            </div>

            <div className="flex justify-end space-x-3">
              <button 
                onClick={() => setExportMode(null)}
                className="px-4 py-2.5 rounded-xl text-xs font-bold border border-slate-200 hover:bg-slate-50 text-cuanly-textDark"
              >
                Batal
              </button>
              <button 
                onClick={handleDownload}
                className="px-4 py-2.5 rounded-xl text-xs font-bold bg-cuanly-mint text-white hover:opacity-90 transition-opacity cursor-pointer"
              >
                Unduh Berkas
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Main Grid: Aggregate view + Team Saving Leaderboard */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
        {/* Aggregate view per department */}
        <div className="lg:col-span-2 bg-cuanly-card border border-cuanly-border rounded-2xl p-6 shadow-sm shadow-slate-100">
          <h3 className="text-base font-bold text-cuanly-textDark mb-1">Pengeluaran Agregat per Departemen</h3>
          <p className="text-xs text-cuanly-textMuted mb-6">Total alokasi dana operasional kuartal ini</p>

          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={deptData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="name" stroke="#64748b" fontSize={11} tickLine={false} />
                <YAxis stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} tickFormatter={(v) => `Rp ${v/1000000}M`} />
                <Tooltip formatter={(v) => formatIDR(v)} />
                <Bar dataKey="Pengeluaran" radius={[4, 4, 0, 0]}>
                  {deptData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Team saving challenge leaderboard */}
        <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 flex flex-col justify-between shadow-sm shadow-slate-100">
          <div>
            <div className="flex items-center space-x-2 text-cuanly-yellow mb-2">
              <Award size={20} />
              <h3 className="text-base font-bold text-cuanly-textDark">Saving Leaderboard</h3>
            </div>
            <p className="text-xs text-cuanly-textMuted mb-6">Kompetisi efisiensi anggaran antar departemen</p>

            <div className="space-y-4">
              {leaderboard.map((team, idx) => (
                <div key={idx} className="space-y-1.5">
                  <div className="flex justify-between items-center text-xs">
                    <div className="flex items-center space-x-2 font-bold text-cuanly-textDark">
                      <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] ${
                        team.rank === 1 ? 'bg-amber-500 text-black' :
                        team.rank === 2 ? 'bg-slate-400 text-black' :
                        team.rank === 3 ? 'bg-amber-700 text-white' : 'bg-slate-200 text-cuanly-textDark'
                      }`}>
                        {team.rank}
                      </span>
                      <span>{team.name}</span>
                    </div>
                    <span className="font-bold text-cuanly-mint">{team.score} Left</span>
                  </div>
                  {/* Progress Line */}
                  <div className="h-1.5 bg-slate-100 rounded-full overflow-hidden">
                    <div 
                      className={`h-full rounded-full ${
                        team.progress > 85 ? 'bg-cuanly-mint' :
                        team.progress > 70 ? 'bg-cuanly-yellow' : 'bg-cuanly-coral'
                      }`} 
                      style={{ width: `${team.progress}%` }}
                    ></div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-100 flex justify-between items-center text-xs">
            <span className="text-cuanly-textMuted">Efisiensi Grup:</span>
            <span className="font-black text-cuanly-mint">+Rp 50.500.000 (Sangat Bagus)</span>
          </div>
        </div>
      </div>

      {/* Approval Flow Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Claims List Table */}
        <div className="lg:col-span-2 bg-cuanly-card border border-cuanly-border rounded-2xl p-6 shadow-sm shadow-slate-100">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h3 className="text-base font-bold text-cuanly-textDark">Persetujuan Klaim Reimbursement</h3>
              <p className="text-xs text-cuanly-textMuted mt-0.5">Alur approval klaim pengeluaran karyawan</p>
            </div>
            <div className="flex items-center space-x-1.5 text-xs text-cuanly-textMuted">
              <Users size={14} />
              <span>4 Pengajuan Aktif</span>
            </div>
          </div>

          <div className="space-y-4">
            {claims.map((claim) => (
              <div 
                key={claim.id} 
                className="flex items-center justify-between p-4 rounded-xl bg-slate-50 border border-slate-100 hover:border-slate-200 transition-all duration-200 cursor-pointer"
                onClick={() => setActivePreviewClaim(claim)}
              >
                <div className="flex items-center space-x-4">
                  <div className={`p-2.5 rounded-xl font-bold text-xs ${
                    claim.status === 'approved' ? 'bg-cuanly-green/10 text-cuanly-green' :
                    claim.status === 'rejected' ? 'bg-cuanly-red/10 text-cuanly-red' : 'bg-cuanly-yellow/10 text-cuanly-yellow'
                  }`}>
                    {claim.status === 'approved' ? <Check size={16} /> :
                     claim.status === 'rejected' ? <X size={16} /> : 'claim'}
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-cuanly-textDark">{claim.title}</h4>
                    <p className="text-[10px] text-cuanly-textMuted">{claim.name} ({claim.department}) • {claim.date}</p>
                  </div>
                </div>

                <div className="flex items-center space-x-3" onClick={(e) => e.stopPropagation()}>
                  <span className="text-xs font-black mr-2 text-cuanly-textDark">{formatIDR(claim.amount)}</span>
                  {claim.status === 'pending' ? (
                    <div className="flex space-x-2">
                      <button 
                        onClick={() => handleApprove(claim.id)}
                        className="p-1.5 rounded-lg bg-cuanly-green/20 hover:bg-cuanly-green/30 text-cuanly-green transition-colors"
                      >
                        <Check size={14} />
                      </button>
                      <button 
                        onClick={() => handleReject(claim.id)}
                        className="p-1.5 rounded-lg bg-cuanly-red/20 hover:bg-cuanly-red/30 text-cuanly-red transition-colors"
                      >
                        <X size={14} />
                      </button>
                    </div>
                  ) : (
                    <span className={`px-2 py-0.5 rounded-md text-[9px] font-bold uppercase tracking-wider ${
                      claim.status === 'approved' ? 'bg-cuanly-green/10 text-cuanly-green border border-cuanly-green/20' :
                      'bg-cuanly-red/10 text-cuanly-red border border-cuanly-red/20'
                    }`}>
                      {claim.status}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="space-y-6">
          {/* Claim Detail Preview Panel */}
          <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 flex flex-col justify-between min-h-[300px] shadow-sm shadow-slate-100">
            {activePreviewClaim ? (
              <>
                <div>
                  <div className="flex justify-between items-start mb-6">
                    <h3 className="text-base font-bold text-cuanly-textDark">Rincian Pengajuan</h3>
                    <span className={`px-2 py-0.5 rounded-md text-[9px] font-bold uppercase tracking-wider ${
                      activePreviewClaim.status === 'approved' ? 'bg-cuanly-green/10 text-cuanly-green' :
                      activePreviewClaim.status === 'rejected' ? 'bg-cuanly-red/10 text-cuanly-red' : 'bg-cuanly-yellow/10 text-cuanly-yellow'
                    }`}>
                      {activePreviewClaim.status}
                    </span>
                  </div>

                  <div className="space-y-4 text-xs">
                    <div>
                      <label className="text-[10px] text-cuanly-textMuted uppercase tracking-wider block">Karyawan</label>
                      <span className="font-bold text-cuanly-textDark block mt-0.5">{activePreviewClaim.name} ({activePreviewClaim.department})</span>
                    </div>
                    <div>
                      <label className="text-[10px] text-cuanly-textMuted uppercase tracking-wider block">Klaim Pengeluaran</label>
                      <span className="font-bold text-cuanly-textDark block mt-0.5">{activePreviewClaim.title}</span>
                    </div>
                    <div>
                      <label className="text-[10px] text-cuanly-textMuted uppercase tracking-wider block">Total Pengajuan</label>
                      <span className="text-sm font-black text-cuanly-violet block mt-0.5">{formatIDR(activePreviewClaim.amount)}</span>
                    </div>
                    <div>
                      <label className="text-[10px] text-cuanly-textMuted uppercase tracking-wider block">Keterangan / Alasan</label>
                      <p className="text-cuanly-textMuted mt-1 leading-relaxed">{activePreviewClaim.description}</p>
                    </div>
                  </div>
                </div>

                {activePreviewClaim.status === 'pending' && (
                  <div className="flex space-x-3 mt-6 pt-4 border-t border-slate-100">
                    <button 
                      onClick={() => handleReject(activePreviewClaim.id)}
                      className="flex-1 py-2 rounded-xl text-xs font-bold border border-cuanly-red/30 text-cuanly-red hover:bg-cuanly-red/10 transition-colors"
                    >
                      Tolak
                    </button>
                    <button 
                      onClick={() => handleApprove(activePreviewClaim.id)}
                      className="flex-1 py-2 rounded-xl text-xs font-bold bg-cuanly-green text-white hover:opacity-90 transition-opacity"
                    >
                      Setujui
                    </button>
                  </div>
                )}
              </>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center text-center p-6 text-cuanly-textMuted">
                <Eye size={36} className="mb-3 text-slate-300" />
                <p className="text-xs">Klik salah satu klaim reimbursement untuk melihat rincian pengajuan dan menyetujui/menolak.</p>
              </div>
            )}
          </div>

          {/* Form Pengajuan Klaim Baru */}
          <div className="bg-cuanly-card border border-cuanly-border rounded-2xl p-6 shadow-sm shadow-slate-100">
            <h3 className="text-base font-bold mb-4 flex items-center space-x-2 text-cuanly-textDark">
              <span className="text-cuanly-violet">📝</span>
              <span>Ajukan Reimbursement Baru</span>
            </h3>
            <form onSubmit={handleAddClaim} className="space-y-3 text-xs">
              <div>
                <label className="text-[10px] text-cuanly-textMuted block mb-1">Nama Karyawan</label>
                <input
                  type="text"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="Andi Saputra"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-cuanly-textDark focus:border-cuanly-violet focus:outline-none"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-[10px] text-cuanly-textMuted block mb-1">Departemen</label>
                  <select
                    value={newDept}
                    onChange={(e) => setNewDept(e.target.value)}
                    className="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-cuanly-textDark focus:border-cuanly-violet focus:outline-none cursor-pointer"
                  >
                    <option value="Engineering">Engineering</option>
                    <option value="Sales">Sales</option>
                    <option value="Marketing">Marketing</option>
                    <option value="HR">HR</option>
                  </select>
                </div>
                <div>
                  <label className="text-[10px] text-cuanly-textMuted block mb-1">Tanggal</label>
                  <input
                    type="date"
                    value={newDate}
                    onChange={(e) => setNewDate(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-cuanly-textDark focus:border-cuanly-violet focus:outline-none cursor-pointer"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-[10px] text-cuanly-textMuted block mb-1">Judul Klaim</label>
                  <input
                    type="text"
                    value={newTitle}
                    onChange={(e) => setNewTitle(e.target.value)}
                    placeholder="AWS Cloud Hosting"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-cuanly-textDark focus:border-cuanly-violet focus:outline-none"
                  />
                </div>
                <div>
                  <label className="text-[10px] text-cuanly-textMuted block mb-1">Jumlah (Rp)</label>
                  <input
                    type="number"
                    value={newAmount}
                    onChange={(e) => setNewAmount(e.target.value)}
                    placeholder="150000"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-cuanly-textDark focus:border-cuanly-violet focus:outline-none"
                  />
                </div>
              </div>
              <div>
                <label className="text-[10px] text-cuanly-textMuted block mb-1">Deskripsi / Keperluan</label>
                <textarea
                  value={newDesc}
                  onChange={(e) => setNewDesc(e.target.value)}
                  placeholder="Keterangan keperluan dinas..."
                  rows={2}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-cuanly-textDark focus:border-cuanly-violet focus:outline-none resize-none"
                />
              </div>
              <button
                type="submit"
                className="w-full py-2.5 rounded-xl text-xs font-bold bg-cuanly-violet text-white hover:opacity-90 transition-opacity cursor-pointer"
              >
                Kirim Pengajuan
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
