#!/bin/bash

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║       SurrealDB Docker Extension - Complete Fix       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    echo "❌ Error: Please run this script from the surrealdb-docker-extension directory"
    echo "   cd surrealdb-docker-extension"
    echo "   ./fix-surrealdb-extension.sh"
    exit 1
fi

echo "📝 Step 1: Backing up original DatabaseManager.tsx..."
cp ui/src/components/DatabaseManager.tsx ui/src/components/DatabaseManager.tsx.backup

echo "✏️  Step 2: Updating DatabaseManager.tsx with fixes..."

cat > ui/src/components/DatabaseManager.tsx << 'EOF'
import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  Typography,
  Grid,
  CircularProgress,
  Alert,
  Chip,
  Stack,
} from '@mui/material';
import {
  PlayArrow as PlayArrowIcon,
  Stop as StopIcon,
  Refresh as RefreshIcon,
  Storage as StorageIcon,
} from '@mui/icons-material';
import { createDockerDesktopClient } from '@docker/extension-api-client';

const ddClient = createDockerDesktopClient();

interface DatabaseManagerProps {
  onStatusChange: () => void;
  connectionStatus: 'connected' | 'disconnected' | 'connecting';
}

const DatabaseManager: React.FC<DatabaseManagerProps> = ({ onStatusChange, connectionStatus }) => {
  const [loading, setLoading] = useState(false);
  const [containerInfo, setContainerInfo] = useState<any>(null);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  useEffect(() => {
    fetchContainerInfo();
  }, []);

  const fetchContainerInfo = async () => {
    try {
      const result = await ddClient.docker.cli.exec('ps', [
        '--filter',
        'name=surrealdb',
        '--format',
        'json',
      ]);

      if (result.stdout) {
        try {
          const info = JSON.parse(result.stdout);
          setContainerInfo(info);
        } catch {
          setContainerInfo(null);
        }
      }
    } catch (error) {
      console.error('Error fetching container info:', error);
    }
  };

  const startSurrealDB = async () => {
    setLoading(true);
    setMessage(null);

    try {
      const result = await ddClient.extension.vm?.cli.exec('docker-compose', [
        '-f',
        '/docker-compose.yaml',
        'up',
        '-d'
      ]);
      
      if (result?.stderr) {
        console.error('Docker compose stderr:', result.stderr);
      }
      
      setMessage({ type: 'success', text: 'SurrealDB started successfully!' });
      setTimeout(() => {
        onStatusChange();
        fetchContainerInfo();
      }, 2000);
    } catch (error: any) {
      console.error('Start error:', error);
      const errorMsg = error?.message || error?.stderr || JSON.stringify(error) || 'Unknown error';
      setMessage({ type: 'error', text: `Failed to start SurrealDB: ${errorMsg}` });
    } finally {
      setLoading(false);
    }
  };

  const stopSurrealDB = async () => {
    setLoading(true);
    setMessage(null);

    try {
      const result = await ddClient.extension.vm?.cli.exec('docker-compose', [
        '-f',
        '/docker-compose.yaml',
        'down'
      ]);
      
      if (result?.stderr) {
        console.error('Docker compose stderr:', result.stderr);
      }
      
      setMessage({ type: 'success', text: 'SurrealDB stopped successfully!' });
      setTimeout(() => {
        onStatusChange();
        fetchContainerInfo();
      }, 1000);
    } catch (error: any) {
      console.error('Stop error:', error);
      const errorMsg = error?.message || error?.stderr || JSON.stringify(error) || 'Unknown error';
      setMessage({ type: 'error', text: `Failed to stop SurrealDB: ${errorMsg}` });
    } finally {
      setLoading(false);
    }
  };

  const restartSurrealDB = async () => {
    setLoading(true);
    setMessage(null);

    try {
      const result = await ddClient.extension.vm?.cli.exec('docker-compose', [
        '-f',
        '/docker-compose.yaml',
        'restart'
      ]);
      
      if (result?.stderr) {
        console.error('Docker compose stderr:', result.stderr);
      }
      
      setMessage({ type: 'success', text: 'SurrealDB restarted successfully!' });
      setTimeout(() => {
        onStatusChange();
        fetchContainerInfo();
      }, 2000);
    } catch (error: any) {
      console.error('Restart error:', error);
      const errorMsg = error?.message || error?.stderr || JSON.stringify(error) || 'Unknown error';
      setMessage({ type: 'error', text: `Failed to restart SurrealDB: ${errorMsg}` });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      {message && (
        <Alert severity={message.type} sx={{ mb: 2 }} onClose={() => setMessage(null)}>
          {message.text}
        </Alert>
      )}

      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 2 }}>
                <StorageIcon color="primary" fontSize="large" />
                <Typography variant="h5">Database Status</Typography>
              </Stack>

              <Box sx={{ mb: 2 }}>
                <Chip
                  label={connectionStatus.toUpperCase()}
                  color={connectionStatus === 'connected' ? 'success' : 'default'}
                  sx={{ mb: 1 }}
                />
              </Box>

              {containerInfo && (
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    Image: surrealdb/surrealdb:latest
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Port: 8000
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Default Credentials: root/root
                  </Typography>
                </Box>
              )}

              <Stack direction="row" spacing={2}>
                <Button
                  variant="contained"
                  startIcon={loading ? <CircularProgress size={20} /> : <PlayArrowIcon />}
                  onClick={startSurrealDB}
                  disabled={loading || connectionStatus === 'connected'}
                >
                  Start
                </Button>

                <Button
                  variant="outlined"
                  startIcon={loading ? <CircularProgress size={20} /> : <StopIcon />}
                  onClick={stopSurrealDB}
                  disabled={loading || connectionStatus === 'disconnected'}
                >
                  Stop
                </Button>

                <Button
                  variant="outlined"
                  startIcon={loading ? <CircularProgress size={20} /> : <RefreshIcon />}
                  onClick={restartSurrealDB}
                  disabled={loading || connectionStatus === 'disconnected'}
                >
                  Restart
                </Button>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h5" gutterBottom>
                Quick Start Guide
              </Typography>

              <Typography variant="body2" paragraph>
                1. Click <strong>Start</strong> to launch SurrealDB
              </Typography>

              <Typography variant="body2" paragraph>
                2. Access SurrealDB at <code>http://localhost:8000</code>
              </Typography>

              <Typography variant="body2" paragraph>
                3. Use the Query Editor tab to run SurrealQL queries
              </Typography>

              <Typography variant="body2" paragraph>
                4. Explore your data in the Data Explorer tab
              </Typography>

              <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
                Default credentials:
                <br />
                Username: <code>root</code>
                <br />
                Password: <code>root</code>
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default DatabaseManager;
EOF

echo "✅ DatabaseManager.tsx updated!"
echo ""

echo "🔨 Step 3: Rebuilding UI..."
cd ui
npm run build
if [ $? -ne 0 ]; then
    echo "❌ UI build failed!"
    exit 1
fi
cd ..
echo "✅ UI built successfully!"
echo ""

echo "🐳 Step 4: Building Docker extension..."
docker build --tag=ajeetraina777/surrealdb-docker-extension:latest .
if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi
echo "✅ Extension image built!"
echo ""

echo "📦 Step 5: Updating extension in Docker Desktop..."
docker extension update ajeetraina777/surrealdb-docker-extension:latest
if [ $? -ne 0 ]; then
    echo "❌ Extension update failed!"
    echo "   Trying to remove and reinstall..."
    docker extension rm ajeetraina777/surrealdb-docker-extension 2>/dev/null || true
    docker extension install ajeetraina777/surrealdb-docker-extension:latest
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║            ✅ FIX COMPLETED SUCCESSFULLY! ✅           ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "🎉 What was fixed:"
echo "   • Added explicit path to docker-compose.yaml (-f /docker-compose.yaml)"
echo "   • Improved error handling to show actual error messages"
echo "   • Added console logging for debugging"
echo ""
echo "📋 Next steps:"
echo "   1. Open Docker Desktop"
echo "   2. Go to Extensions → SurrealDB"
echo "   3. Click the START button"
echo "   4. If it still fails, check the browser console (F12) for error details"
echo ""
echo "💾 Backup saved at: ui/src/components/DatabaseManager.tsx.backup"
echo ""
