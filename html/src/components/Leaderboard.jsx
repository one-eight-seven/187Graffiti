const MEDALS = ['🥇', '🥈', '🥉']

export default function Leaderboard({ entries, totalWalls }) {
    if (!entries || entries.length === 0) {
        return (
            <div style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '40px 0' }}>
                <div style={{ fontSize: '32px' }}>🏙️</div>
                <div style={{ marginTop: '8px' }}>No territories claimed yet.</div>
            </div>
        )
    }

    return (
        <div>
            <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                color: 'var(--text-secondary)',
                fontSize: '11px',
                padding: '0 4px',
                marginBottom: '8px',
                textTransform: 'uppercase',
                letterSpacing: '0.5px',
            }}>
                <span>Gang</span>
                <span>Walls</span>
            </div>

            <div className="item-list">
                {entries.map((entry, i) => {
                    const pct = totalWalls > 0 ? Math.round((entry.walls / totalWalls) * 100) : 0
                    return (
                        <div key={entry.gang} className="item">
                            <div className="item-left">
                                <div className="item-icon">{MEDALS[i] ?? `#${i + 1}`}</div>
                                <div>
                                    <div className="item-name">{entry.gang}</div>
                                    <div className="item-sub">{pct}% of territory</div>
                                </div>
                            </div>
                            <span className="badge badge-accent">{entry.walls}</span>
                        </div>
                    )
                })}
            </div>
        </div>
    )
}
