export default function WallInfo({ wall, sprayCount, playerGang, tagStyles = [] }) {
    if (!wall) return null

    const isOwn     = wall.ownerGang && wall.ownerGang === playerGang
    const tagStyle  = tagStyles.find(s => s.id === wall.tagStyle)

    return (
        <div style={{ marginBottom: '12px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <span style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>{wall.name}</span>
                {wall.ownerGang
                    ? <span className={`badge ${isOwn ? 'badge-success' : 'badge-danger'}`}>{wall.ownerGang}</span>
                    : <span className="badge badge-success">Unclaimed</span>
                }
            </div>

            {wall.ownerGang && tagStyle && (
                <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '6px' }}>
                    {tagStyle.emoji} {tagStyle.label} tag
                </div>
            )}

            {!wall.ownerGang && !wall.contestGang && (
                <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '6px' }}>
                    Spray {sprayCount} times to claim this wall.
                </div>
            )}

            {wall.contestGang && (
                <div style={{
                    background: 'rgba(245,158,11,0.1)',
                    border: '1px solid rgba(245,158,11,0.3)',
                    borderRadius: '8px',
                    padding: '8px 12px',
                    fontSize: '12px',
                    color: 'var(--warning)',
                }}>
                    ⚠ Contested by <strong>{wall.contestGang}</strong>
                    {' '}— {wall.contestCount}/{sprayCount} sprays
                    <div className="progress-bar" style={{ marginTop: '6px' }}>
                        <div
                            className="progress-fill"
                            style={{ width: `${Math.min(100, (wall.contestCount / sprayCount) * 100)}%` }}
                        />
                    </div>
                </div>
            )}
        </div>
    )
}
