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
      const containerName = 'surrealdb-ext';
      
      // Remove any existing container with the same name (stopped or running)
      try {
        await ddClient.docker.cli.exec('rm', ['-f', containerName]);
        console.log('Removed existing container');
      } catch (e) {
        console.log('No existing container to remove');
      }

      // Create and start new container on port 8001
      await ddClient.docker.cli.exec('run', [
        '-d',
        '--name', containerName,
        '-p', '8001:8000',
        '-v', 'surrealdb_data:/mydata',
        'surrealdb/surrealdb:latest',
        'start',
        '--log', 'trace',
        '--user', 'root',
        '--pass', 'root'
      ]);
      
      setMessage({ type: 'success', text: 'SurrealDB started successfully on port 8001!' });
      setTimeout(() => {
        onStatusChange();
        fetchContainerInfo();
      }, 2000);
    } catch (error: any) {
      console.error('Start error:', error);
      const errorMsg = error?.stderr || error?.message || JSON.stringify(error) || 'Unknown error';
      setMessage({ type: 'error', text: `Failed to start SurrealDB: ${errorMsg}` });
    } finally {
      setLoading(false);
    }
  };

  const stopSurrealDB = async () => {
    setLoading(true);
    setMessage(null);

    try {
      await ddClient.docker.cli.exec('stop', ['surrealdb-ext']);
      setMessage({ type: 'success', text: 'SurrealDB stopped successfully!' });
      setTimeout(() => {
        onStatusChange();
        fetchContainerInfo();
      }, 1000);
    } catch (error: any) {
      console.error('Stop error:', error);
      const errorMsg = error?.stderr || error?.message || JSON.stringify(error) || 'Unknown error';
      setMessage({ type: 'error', text: `Failed to stop SurrealDB: ${errorMsg}` });
    } finally {
      setLoading(false);
    }
  };

  const restartSurrealDB = async () => {
    setLoading(true);
    setMessage(null);

    try {
      await ddClient.docker.cli.exec('restart', ['surrealdb-ext']);
      setMessage({ type: 'success', text: 'SurrealDB restarted successfully!' });
      setTimeout(() => {
        onStatusChange();
        fetchContainerInfo();
      }, 2000);
    } catch (error: any) {
      console.error('Restart error:', error);
      const errorMsg = error?.stderr || error?.message || JSON.stringify(error) || 'Unknown error';
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
                    Port: 8001 (Host) → 8000 (Container)
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
                2. Access SurrealDB at <code>http://localhost:8001</code>
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
