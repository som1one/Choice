import env from '../env';
import 'react-native-url-polyfill/auto';
import { DeviceEventEmitter } from 'react-native';

let socket = null;
let token = '';
let intentionallyClosed = false;

const mapMessageType = (type) => {
    if (type === 'Image' || type === '2' || type === 2) {
        return '2';
    }

    if (type === 'Order' || type === '3' || type === 3) {
        return '3';
    }

    return '1';
};

const mapChatMessage = (message = {}) => ({
    id: message.id,
    receiverId: message.receiver_id || message.receiverId,
    senderId: message.sender_id || message.senderId,
    creationTime: message.creation_time || message.creationTime || new Date().toISOString(),
    body: message.text || message.body || '',
    type: mapMessageType(message.message_type || message.type),
    isRead: message.is_read ?? message.isRead ?? false
});

const buildOrderBody = (order = {}) => JSON.stringify({
    OrderId: order.order_id ?? order.orderId,
    OrderRequestId: order.order_request_id ?? order.orderRequestId,
    Price: order.price ?? 0,
    Prepayment: order.prepayment ?? 0,
    Deadline: order.deadline ?? 0,
    IsEnrolled: order.is_enrolled ?? order.isEnrolled ?? false,
    EnrollmentTime: order.enrollment_date ?? order.enrollmentDate ?? null,
    Status: order.status ?? 0,
    IsActive: true,
    IsDateConfirmed: order.is_date_confirmed ?? order.isDateConfirmed ?? false,
    UserChangedEnrollmentDate: order.user_changed_enrollment_date_guid ?? order.userChangedEnrollmentDateGuid ?? null
});

const buildOrderMessage = (payload = {}) => ({
    id: payload.order_id ?? Date.now(),
    receiverId: payload.client_id || payload.clientId,
    senderId: payload.company_id || payload.companyId,
    creationTime: new Date().toISOString(),
    body: buildOrderBody(payload),
    type: '3',
    isRead: true
});

const toWsUrl = () => {
    const apiUrl = env.chat_ws_url || env.api_url || '';
    const normalized = apiUrl
        .replace(/^https:\/\//i, 'wss://')
        .replace(/^http:\/\//i, 'ws://')
        .replace(/\/+$/, '');

    return `${normalized}/ws/chat?token=${encodeURIComponent(token)}`;
};

const handleMessage = (event) => {
    try {
        const data = JSON.parse(event.data);
        const type = data?.type;

        if (type === 'send') {
            const mapped = mapChatMessage(data.message || {});
            DeviceEventEmitter.emit('messageReceived', mapped);
            DeviceEventEmitter.emit('tabMessageReceived');
            return;
        }

        if (type === 'read') {
            const mapped = mapChatMessage(data.message || {});
            DeviceEventEmitter.emit('read', mapped);
            return;
        }

        if (type === 'enrollmentDateChanged') {
            const mapped = buildOrderMessage(data.order || data);
            DeviceEventEmitter.emit('enrollmentDateChanged', mapped);
            DeviceEventEmitter.emit('tabMessageReceived');
            return;
        }

        if (type === 'enrolled' || type === 'confirmed' || type === 'statusChanged') {
            const mapped = buildOrderMessage(data.order || data);
            DeviceEventEmitter.emit('messageChanged', mapped);
            if (type !== 'statusChanged') {
                DeviceEventEmitter.emit('tabMessageReceived');
            }
            return;
        }

        if (type === 'userStatusChanged') {
            const user = {
                guid: data.user_id,
                status: data.status === 'Online' ? 1 : 2,
                lastTimeOnline: data.status === 'Online' ? null : new Date().toISOString()
            };
            DeviceEventEmitter.emit('chatChanged', user);
        }
    } catch (e) {
        console.log('WebSocket parse error:', e?.message || e);
    }
};

const build = (newToken) => {
    token = newToken || '';
};

const start = async () => {
    if (!token) {
        return false;
    }

    if (socket && (socket.readyState === WebSocket.OPEN || socket.readyState === WebSocket.CONNECTING)) {
        return true;
    }

    intentionallyClosed = false;

    return await new Promise((resolve) => {
        let resolved = false;
        const safeResolve = (value) => {
            if (!resolved) {
                resolved = true;
                resolve(value);
            }
        };

        try {
            socket = new WebSocket(toWsUrl());

            socket.onopen = () => safeResolve(true);
            socket.onmessage = handleMessage;
            socket.onerror = (e) => {
                console.log('WebSocket error:', e?.message || e);
                safeResolve(false);
            };
            socket.onclose = (e) => {
                if (!intentionallyClosed) {
                    DeviceEventEmitter.emit('closed');
                }
                if (!resolved) {
                    safeResolve(false);
                }
            };

            setTimeout(() => safeResolve(socket?.readyState === WebSocket.OPEN), 5000);
        } catch (e) {
            console.log('WebSocket start failed:', e?.message || e);
            safeResolve(false);
        }
    });
};

const stop = async () => {
    intentionallyClosed = true;

    if (socket) {
        try {
            socket.close();
        } catch (_) {
            // ignore close errors
        }
    }

    socket = null;
};

export default {
    build,
    start,
    stop
};
