import { io, Socket } from 'socket.io-client'

let socket: Socket | null = null

export function initializeSocket(): Socket {
  if (!socket) {
    socket = io(process.env.NEXT_PUBLIC_SOCKET_URL || 'ws://localhost:3001', {
      transports: ['websocket'],
      autoConnect: false,
    })
  }
  return socket
}

export function getSocket(): Socket | null {
  return socket
}

export function disconnectSocket(): void {
  if (socket) {
    socket.disconnect()
    socket = null
  }
}
