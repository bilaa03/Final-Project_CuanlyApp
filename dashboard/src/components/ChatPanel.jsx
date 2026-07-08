import React, { useState, useRef, useEffect } from 'react';
import { X, Send, Sparkles, Smile, Flame, ShieldAlert } from 'lucide-react';

export function ChatPanel({ isOpen, onClose, user, transactions }) {
  const [messages, setMessages] = useState([
    {
      isUser: false,
      text: 'Halo! Saya Cuanly, asisten intelijen keuangan pribadi Anda. Tanyakan apa saja tentang pola pengeluaran atau anggaran Anda.',
      directAnswer: null,
      contextBadge: null,
      rekomendasi: ['Berapa pengeluaranku bulan ini?', 'Apakah anggaranku aman?'],
    }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [roastMode, setRoastMode] = useState(false);
  const [segment, setSegment] = useState('b2c'); // b2c (Personal) vs b2b (Business)
  const [mood, setMood] = useState('😎 Relaks'); // Mood states: 😎 Relaks, 😟 Cemas, 🚨 Panik

  const messagesEndRef = useRef(null);

  // Auto-scroll to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  // Dynamically update mood based on transactions
  useEffect(() => {
    const expenses = transactions.filter(t => t.isExpense).reduce((sum, t) => sum + t.amount, 0);
    if (expenses > 3000000) {
      setMood('🚨 Panik');
    } else if (expenses > 1500000) {
      setMood('😟 Cemas');
    } else {
      setMood('😎 Relaks');
    }
  }, [transactions]);

  const handleSend = async (e) => {
    e.preventDefault();
    if (!input.trim() || loading) return;

    const userMsg = input.trim();
    setInput('');
    setMessages(prev => [...prev, { isUser: true, text: userMsg }]);
    setLoading(true);

    try {
      const res = await fetch('/rag/query', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          question: userMsg,
          userSegment: segment,
          docType: 'auto',
          topK: 3
        }),
      });

      if (!res.ok) throw new Error('API Error');
      const data = await res.json();

      let answerText = data.jawaban || 'Maaf, saya tidak bisa menemukan data tersebut.';
      
      // Inject sarcastic "Roast" text if roastMode is enabled
      if (roastMode) {
        answerText += '\n\n🔥 *ROAST MODE:* Wah belanja kamu heboh banget ya! Dompet kamu udah teriak minta tolong tuh, kurangi nongkrong kopi cantiknya!';
      }

      let recs = [];
      if (Array.isArray(data.rekomendasi)) {
        recs = data.rekomendasi;
      } else if (typeof data.rekomendasi === 'string') {
        recs = [data.rekomendasi];
      } else {
        recs = ['Rincian kategori pengeluaran', 'Tips hemat anggaran'];
      }

      setMessages(prev => [...prev, {
        isUser: false,
        text: answerText,
        directAnswer: data.jawaban?.match(/Rp\s*[0-9.]+|[0-9]+%/g)?.[0] || null, // Extract first number/pct as direct answer
        contextBadge: data.jawaban?.includes('naik') ? '▲ Naik' : data.jawaban?.includes('turun') ? '▼ Turun' : '■ Stabil',
        rekomendasi: recs,
      }]);
    } catch (err) {
      // Fallback offline simulator
      setTimeout(() => {
        let simulatedText = 'Asisten Keuangan Offline: Jawaban simulasi lokal karena server API sedang offline.';
        if (roastMode) {
          simulatedText += '\n\n🔥 *ROAST MODE:* Stop belanja barang tidak berguna! Rekening Anda sekarat!';
        }
        setMessages(prev => [...prev, {
          isUser: false,
          text: simulatedText,
          directAnswer: 'Rp 1.400.000',
          contextBadge: '▲ Naik 12%',
          rekomendasi: ['Tips hemat makanan', 'Cara split bill'],
        }]);
      }, 1000);
    } finally {
      setLoading(false);
    }
  };

  const handleChipClick = (question) => {
    setInput(question);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-y-0 right-0 w-96 bg-cuanly-card border-l border-cuanly-border z-40 flex flex-col justify-between shadow-2xl shadow-black/80 animate-slideLeft">
      {/* Header */}
      <div className="p-4 border-b border-cuanly-border flex items-center justify-between bg-cuanly-card">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-cuanly-violet to-cuanly-violetLight flex items-center justify-center text-white">
            <Sparkles size={16} />
          </div>
          <div>
            <h3 className="text-xs font-black text-white">Cuanly Chat</h3>
            <p className="text-[9px] text-cuanly-textMuted font-bold uppercase tracking-wider">Cuanly Intelligence</p>
          </div>
        </div>
        <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-white/5 text-cuanly-textMuted hover:text-white transition-colors">
          <X size={18} />
        </button>
      </div>

      {/* Mood Spending + Roast Mode bar */}
      <div className="px-4 py-2 border-b border-cuanly-border bg-white/5 flex items-center justify-between text-xs">
        <div className="flex items-center space-x-1">
          <Smile size={14} className="text-cuanly-mint" />
          <span className="text-cuanly-textMuted">Mood Spending:</span>
          <span className="font-bold text-white">{mood}</span>
        </div>

        {/* Roast Mode Toggle button */}
        <button
          onClick={() => setRoastMode(!roastMode)}
          className={`flex items-center space-x-1.5 px-3 py-1 rounded-full text-[10px] font-bold border transition-all duration-200 ${
            roastMode
              ? 'bg-cuanly-coral/10 border-cuanly-coral/30 text-cuanly-coral shadow-lg shadow-cuanly-coral/10'
              : 'border-white/10 text-cuanly-textMuted hover:text-white'
          }`}
        >
          <Flame size={12} className={roastMode ? 'animate-bounce' : ''} />
          <span>Roast Mode: {roastMode ? 'ON' : 'OFF'}</span>
        </button>
      </div>

      {/* Segment Selector tabs */}
      <div className="px-4 py-2 border-b border-cuanly-border bg-cuanly-card flex space-x-2">
        <button
          onClick={() => setSegment('b2c')}
          className={`flex-1 py-1.5 rounded-lg text-[10px] font-bold border text-center transition-all duration-200 ${
            segment === 'b2c'
              ? 'bg-cuanly-violet/10 border-cuanly-violet/30 text-cuanly-violetLight'
              : 'border-transparent text-cuanly-textMuted hover:text-white'
          }`}
        >
          Personal (B2C)
        </button>
        <button
          onClick={() => setSegment('b2b')}
          className={`flex-1 py-1.5 rounded-lg text-[10px] font-bold border text-center transition-all duration-200 ${
            segment === 'b2b'
              ? 'bg-cuanly-violet/10 border-cuanly-violet/30 text-cuanly-violetLight'
              : 'border-transparent text-cuanly-textMuted hover:text-white'
          }`}
        >
          Bisnis (B2B)
        </button>
      </div>

      {/* Messages list */}
      <div className="flex-1 p-4 overflow-y-auto space-y-4">
        {messages.map((msg, idx) => (
          <div key={idx} className={`flex flex-col ${msg.isUser ? 'items-end' : 'items-start'}`}>
            <div className={`max-w-[85%] rounded-2xl p-4 text-xs leading-relaxed ${
              msg.isUser 
                ? 'bg-cuanly-violet text-white rounded-tr-none' 
                : 'bg-white/5 border border-white/5 text-gray-200 rounded-tl-none relative overflow-hidden group'
            }`}>
              {/* Premium 3-part structured visual layout for AI */}
              {!msg.isUser && (
                <>
                  {/* Part 1: Direct Answer */}
                  {msg.directAnswer && (
                    <div className="text-lg font-black text-cuanly-violetLight tracking-tight mb-1">
                      {msg.directAnswer}
                    </div>
                  )}
                  {/* Part 2: Context Badge */}
                  {msg.contextBadge && (
                    <span className="inline-block px-2 py-0.5 rounded text-[9px] font-bold bg-white/5 border border-white/10 text-cuanly-mint mb-3 uppercase">
                      {msg.contextBadge}
                    </span>
                  )}
                </>
              )}

              {/* Part 3: Main text description */}
              <p className="whitespace-pre-line">{msg.text}</p>
            </div>

            {/* Quick replies recommendation chips */}
            {!msg.isUser && msg.rekomendasi && (
              <div className="flex flex-wrap gap-2 mt-2 max-w-[90%]">
                {msg.rekomendasi.map((rec, rIdx) => (
                  <button
                    key={rIdx}
                    onClick={() => handleChipClick(rec)}
                    className="px-3 py-1.5 rounded-xl bg-white/5 border border-white/5 hover:border-cuanly-violet/40 hover:bg-white/10 text-[10px] font-bold text-cuanly-textMuted hover:text-white transition-all duration-200"
                  >
                    {rec}
                  </button>
                ))}
              </div>
            )}
          </div>
        ))}

        {/* Typing indicator */}
        {loading && (
          <div className="flex items-start">
            <div className="bg-white/5 border border-white/5 rounded-2xl rounded-tl-none p-3 flex space-x-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-cuanly-textMuted animate-bounce" style={{ animationDelay: '0ms' }}></span>
              <span className="w-1.5 h-1.5 rounded-full bg-cuanly-textMuted animate-bounce" style={{ animationDelay: '150ms' }}></span>
              <span className="w-1.5 h-1.5 rounded-full bg-cuanly-textMuted animate-bounce" style={{ animationDelay: '300ms' }}></span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Form */}
      <form onSubmit={handleSend} className="p-4 border-t border-cuanly-border bg-cuanly-card flex items-center space-x-2">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Tanya Cuanly..."
          className="flex-1 bg-white/5 border border-cuanly-border rounded-xl px-4 py-3 text-xs focus:border-cuanly-violet focus:outline-none text-white placeholder-cuanly-textMuted"
        />
        <button
          type="submit"
          disabled={!input.trim() || loading}
          className="p-3 rounded-xl bg-cuanly-violet text-white hover:opacity-90 disabled:opacity-40 transition-opacity flex items-center justify-center"
        >
          <Send size={14} />
        </button>
      </form>
    </div>
  );
}
