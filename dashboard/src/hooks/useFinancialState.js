import { useState, useEffect, useCallback } from 'react';

const API_BASE_URL = ''; // Relative path since they are hosted on the same server

export function useFinancialState() {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('cuanly_user');
    return saved ? JSON.parse(saved) : null;
  });

  const [wallets, setWallets] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [budgetLimit, setBudgetLimit] = useState(() => {
    const saved = localStorage.getItem('cuanly_budget_limit');
    return saved ? Number(saved) : 3000000;
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Fetch wallets and transactions from backend
  const fetchData = useCallback(async (email) => {
    if (!email) return;
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${API_BASE_URL}/financial/data?email=${encodeURIComponent(email)}`);
      if (!res.ok) throw new Error('Gagal mengambil data finansial.');
      const data = await res.json();
      setWallets(data.wallets || []);
      setTransactions(data.transactions || []);
    } catch (err) {
      setError(err.message);
      // Fallback local mock data for preview/offline mode
      _loadMockDataFallback();
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (user?.email) {
      fetchData(user.email);
    } else {
      setWallets([]);
      setTransactions([]);
    }
  }, [user, fetchData]);

  const _loadMockDataFallback = () => {
    setWallets([
      { name: 'Bank Mandiri', balance: 3500000, cardNumber: '•••• 8821', designType: 'blue' },
      { name: 'GoPay', balance: 500000, cardNumber: '0812 •••• 9012', designType: 'teal' },
      { name: 'OVO', balance: 200000, cardNumber: '0812 •••• 9012', designType: 'purple' },
      { name: 'Cash', balance: 120000, cardNumber: 'Fisik', designType: 'slate' },
    ]);
    setTransactions([
      { id: 't1', title: 'Restoran & Coffee Shop', category: 'Makanan', date: new Date().toISOString(), amount: 650000, isExpense: true, wallet: 'Cash' },
      { id: 't2', title: 'Grab Ride', category: 'Transport', date: new Date(Date.now() - 2 * 24 * 3600 * 1000).toISOString(), amount: 320000, isExpense: true, wallet: 'GoPay' },
      { id: 't3', title: 'Belanja Indomaret', category: 'Belanja', date: new Date(Date.now() - 4 * 3600 * 1000).toISOString(), amount: 430000, isExpense: true, wallet: 'Bank Mandiri' },
      { id: 't4', title: 'Gaji Bulanan', category: 'Pemasukan', date: new Date(Date.now() - 3 * 24 * 3600 * 1000).toISOString(), amount: 3500000, isExpense: false, wallet: 'Bank Mandiri' },
    ]);
  };

  const login = async (email, password) => {
    setError(null);
    try {
      const res = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Gagal login.');
      
      const loggedUser = { name: data.user.name, email: data.user.email };
      setUser(loggedUser);
      localStorage.setItem('cuanly_user', JSON.stringify(loggedUser));
      return true;
    } catch (err) {
      setError(err.message);
      return false;
    }
  };

  const register = async (name, email, password) => {
    setError(null);
    try {
      const res = await fetch(`${API_BASE_URL}/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, password }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Gagal mendaftar.');
      return true;
    } catch (err) {
      setError(err.message);
      return false;
    }
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('cuanly_user');
    setWallets([]);
    setTransactions([]);
  };

  const addWallet = async (name, balance, cardNumber, designType) => {
    if (!user) return false;
    try {
      const res = await fetch(`${API_BASE_URL}/financial/wallet`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: user.email,
          name,
          balance: Number(balance),
          cardNumber,
          designType,
        }),
      });
      if (!res.ok) throw new Error('Gagal membuat dompet baru.');
      await fetchData(user.email);
      return true;
    } catch (err) {
      setError(err.message);
      return false;
    }
  };

  const addTransaction = async (id, title, category, date, amount, isExpense, walletName) => {
    if (!user) return false;
    try {
      const res = await fetch(`${API_BASE_URL}/financial/transaction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: user.email,
          id,
          title,
          category,
          date,
          amount: Number(amount),
          isExpense: Boolean(isExpense),
          walletName,
        }),
      });
      if (!res.ok) throw new Error('Gagal mencatat transaksi.');
      await fetchData(user.email);
      return true;
    } catch (err) {
      setError(err.message);
      return false;
    }
  };

  const updateBudgetLimit = (newLimit) => {
    setBudgetLimit(newLimit);
    localStorage.setItem('cuanly_budget_limit', String(newLimit));
  };

  const updateProfile = (name, email, avatarUrl) => {
    setUser(prev => {
      if (!prev) return null;
      const updated = { ...prev, name, email, avatar: avatarUrl || prev.avatar };
      localStorage.setItem('cuanly_user', JSON.stringify(updated));
      return updated;
    });
  };

  // Calculations
  const totalSaldo = wallets.reduce((sum, w) => sum + w.balance, 0);
  const totalPemasukan = transactions.filter(t => !t.isExpense).reduce((sum, t) => sum + t.amount, 0);
  const totalPengeluaran = transactions.filter(t => t.isExpense).reduce((sum, t) => sum + t.amount, 0);
  const savingRatio = totalPemasukan > 0 ? Math.round(((totalPemasukan - totalPengeluaran) / totalPemasukan) * 100) : 0;
  const budgetPct = budgetLimit > 0 ? (totalPengeluaran / budgetLimit) : 0;

  return {
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
    addTransaction,
    updateBudgetLimit,
    updateProfile,
    refreshData: () => fetchData(user?.email),
  };
}
