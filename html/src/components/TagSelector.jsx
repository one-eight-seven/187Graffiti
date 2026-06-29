export default function TagSelector({ styles, selected, onSelect }) {
    return (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '8px' }}>
            {styles.map(style => (
                <div
                    key={style.id}
                    className={`item${selected === style.id ? ' active' : ''}`}
                    style={{ flexDirection: 'column', padding: '12px 8px', textAlign: 'center', cursor: 'pointer', gap: '4px' }}
                    onClick={() => onSelect(style.id)}
                >
                    <div style={{ fontSize: '22px' }}>{style.emoji}</div>
                    <div className="item-name" style={{ fontSize: '11px' }}>{style.label}</div>
                </div>
            ))}
        </div>
    )
}
