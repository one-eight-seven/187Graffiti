import { useState, useEffect, useCallback } from 'react'
import TagSelector from './components/TagSelector'
import WallInfo from './components/WallInfo'
import Leaderboard from './components/Leaderboard'

function App() {
    const [visible, setVisible]         = useState(false)
    const [activeTab, setActiveTab]     = useState('spray')
    const [wall, setWall]               = useState(null)
    const [playerGang, setPlayerGang]   = useState(null)
    const [selectedStyle, setSelected]  = useState(null)
    const [tagStyles, setTagStyles]     = useState([])
    const [leaderboard, setLeaderboard] = useState([])
    const [totalWalls, setTotalWalls]   = useState(0)
    const [sprayCount, setSprayCount]   = useState(5)

    const close = useCallback(() => {
        setVisible(false)
        S187.post('close')
    }, [])

    useEffect(() => {
        const handler = ({ data }) => {
            if (data.action === 'open') {
                const d = data.data
                setWall(d.wall)
                setPlayerGang(d.playerGang)
                setTagStyles(d.tagStyles || [])
                setLeaderboard(d.leaderboard || [])
                setTotalWalls(d.totalWalls || 0)
                setSprayCount(d.sprayCount || 5)
                setSelected(d.tagStyles?.[0]?.id ?? null)
                setActiveTab('spray')
                setVisible(true)
            } else if (data.action === 'leaderboardUpdate') {
                setLeaderboard(data.leaderboard || [])
            }
        }
        window.addEventListener('message', handler)
        return () => window.removeEventListener('message', handler)
    }, [])

    useEffect(() => {
        if (visible) S187.onEscape(close)
    }, [visible, close])

    const handleSpray = () => {
        if (!selectedStyle || !wall) return
        S187.post('spray', { wallId: wall.id, tagStyle: selectedStyle })
        setVisible(false)
    }

    if (!visible) return null

    const isEnemy     = wall?.ownerGang && wall.ownerGang !== playerGang
    const isOwnWall   = wall?.ownerGang && wall.ownerGang === playerGang
    const isUnclaimed = !wall?.ownerGang
    const canSpray    = playerGang && playerGang !== '' && selectedStyle

    const sprayLabel = isUnclaimed ? '🖌️ Claim Wall'
                     : isEnemy     ? '🖌️ Contest Wall'
                     :               '🖌️ Defend Wall'

    return (
        <div
            className="panel"
            style={{ width: '520px', position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)' }}
        >
            <div className="panel-header">
                <div className="panel-title">
                    <div className="icon">🎨</div>
                    Graffiti Tag
                </div>
                <button className="btn-close" onClick={close}>✕</button>
            </div>

            <div className="panel-body">
                <div className="tabs" style={{ marginBottom: '16px' }}>
                    <div
                        className={`tab${activeTab === 'spray' ? ' active' : ''}`}
                        onClick={() => setActiveTab('spray')}
                    >
                        🖌️ Tag Wall
                    </div>
                    <div
                        className={`tab${activeTab === 'territory' ? ' active' : ''}`}
                        onClick={() => setActiveTab('territory')}
                    >
                        🏙️ Territory
                    </div>
                </div>

                {activeTab === 'spray' && (
                    <>
                        <WallInfo wall={wall} sprayCount={sprayCount} />
                        <div className="divider" />

                        <div style={{ marginBottom: '12px' }}>
                            <div style={{
                                fontSize: '12px',
                                color: 'var(--text-secondary)',
                                marginBottom: '8px',
                                textTransform: 'uppercase',
                                letterSpacing: '0.5px',
                            }}>
                                Select Tag Style
                            </div>
                            <TagSelector styles={tagStyles} selected={selectedStyle} onSelect={setSelected} />
                        </div>

                        <div className="divider" />

                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
                            {playerGang && playerGang !== '' ? (
                                <>
                                    <span style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>Your gang:</span>
                                    <span className="badge badge-accent">{playerGang}</span>
                                </>
                            ) : (
                                <span style={{ color: 'var(--danger)', fontSize: '12px' }}>No gang assigned</span>
                            )}
                            {isEnemy && (
                                <span className="badge badge-warning" style={{ marginLeft: 'auto' }}>
                                    Enemy territory
                                </span>
                            )}
                            {isOwnWall && (
                                <span className="badge badge-success" style={{ marginLeft: 'auto' }}>
                                    Your territory
                                </span>
                            )}
                        </div>

                        <div style={{ display: 'flex', gap: '8px' }}>
                            <button
                                className="btn btn-primary"
                                style={{ flex: 1 }}
                                onClick={handleSpray}
                                disabled={!canSpray}
                            >
                                {sprayLabel}
                            </button>
                            <button className="btn btn-secondary" onClick={close}>
                                Cancel
                            </button>
                        </div>
                    </>
                )}

                {activeTab === 'territory' && (
                    <Leaderboard entries={leaderboard} totalWalls={totalWalls} />
                )}
            </div>
        </div>
    )
}

export default App
