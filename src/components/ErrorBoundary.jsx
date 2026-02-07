import { Component } from 'react';

export class ErrorBoundary extends Component {
  state = { error: null };

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    console.error('App error:', error, info);
  }

  render() {
    if (this.state.error) {
      return (
        <div style={{
          padding: 24,
          fontFamily: 'system-ui',
          color: '#1A120B',
          background: '#F5F2E8',
          minHeight: '100vh',
          display: 'flex',
          flexDirection: 'column',
          gap: 16,
        }}>
          <h2 style={{ margin: 0, fontSize: 18 }}>Something went wrong</h2>
          <pre style={{
            background: '#E5E0D8',
            padding: 16,
            borderRadius: 8,
            overflow: 'auto',
            fontSize: 12,
          }}>
            {this.state.error?.message || String(this.state.error)}
          </pre>
        </div>
      );
    }
    return this.props.children;
  }
}
