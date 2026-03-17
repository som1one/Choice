import * as KeyChain from 'react-native-keychain';
import env from '../env';
import { DeviceEventEmitter } from 'react-native';

let readMessages = [];
const baseUrl = env.chat_url || env.api_url;

const jsonHeaders = {
    Accept: 'application/json',
    'Content-Type': 'application/json'
};

const getTokenHeader = async () => {
    const token = await KeyChain.getGenericPassword();
    return token?.password ? { Authorization: `Bearer ${token.password}` } : {};
};

const parseJsonSafe = async (response) => {
    try {
        return await response.json();
    } catch (_) {
        return null;
    }
};

const mapMessageType = (type) => {
    if (type === '1' || type === 1 || type === 'Text') {
        return '1';
    }
    if (type === '2' || type === 2 || type === 'Image') {
        return '2';
    }
    if (type === '3' || type === 3 || type === 'Order') {
        return '3';
    }
    return '1';
};

const mapMessage = (raw) => {
    if (!raw) {
        return null;
    }

    return {
        id: raw.id,
        receiverId: raw.receiverId || raw.receiver_id,
        senderId: raw.senderId || raw.sender_id,
        creationTime: raw.creationTime || raw.creation_time,
        body: raw.body || raw.text || '',
        type: mapMessageType(raw.type || raw.message_type),
        isRead: raw.isRead ?? raw.is_read ?? false
    };
};

const mapStatus = (status) => {
    if (status === 1 || status === 'Online') {
        return 1;
    }
    if (status === 0 || status === 'Offline') {
        return 2;
    }
    return status ?? 2;
};

const mapChat = (raw) => {
    if (!raw) {
        return null;
    }

    const messages = Array.isArray(raw.messages) ? raw.messages.map(mapMessage).filter(Boolean) : [];

    return {
        name: raw.name || '',
        iconUri: raw.iconUri || raw.icon_uri || '',
        guid: raw.guid,
        isDeleted: raw.isDeleted ?? raw.is_deleted ?? false,
        messages,
        status: mapStatus(raw.status),
        lastTimeOnline: raw.lastTimeOnline || raw.last_time_online || null
    };
};

const getMessages = async (receiverId) => {
    const authHeader = await getTokenHeader();

    const response = await fetch(`${baseUrl}/api/message/getMessages?receiver_id=${encodeURIComponent(receiverId)}`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });

    const json = await parseJsonSafe(response);
    const list = Array.isArray(json) ? json : [];
    return list.map(mapMessage).filter(Boolean);
};

const getChat = async (userId) => {
    const authHeader = await getTokenHeader();

    const response = await fetch(`${baseUrl}/api/message/getChat?user_id=${encodeURIComponent(userId)}`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });

    return mapChat(await parseJsonSafe(response));
};

const getChats = async () => {
    const authHeader = await getTokenHeader();

    const response = await fetch(`${baseUrl}/api/message/getChats`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });

    const json = await parseJsonSafe(response);
    const list = Array.isArray(json) ? json : [];
    return list.map(mapChat).filter(Boolean);
};

const sendMessage = async (text, receiverId) => {
    const authHeader = await getTokenHeader();

    const response = await fetch(`${baseUrl}/api/message/send`, {
        method: 'POST',
        body: JSON.stringify({
            receiver_id: receiverId,
            text
        }),
        headers: { ...jsonHeaders, ...authHeader }
    });

    return mapMessage(await parseJsonSafe(response));
};

const sendImage = async (uri, receiverId) => {
    const authHeader = await getTokenHeader();

    const response = await fetch(`${baseUrl}/api/message/sendImage`, {
        method: 'POST',
        body: JSON.stringify({
            receiver_id: receiverId,
            uri
        }),
        headers: { ...jsonHeaders, ...authHeader }
    });

    return mapMessage(await parseJsonSafe(response));
};

const read = async (id) => {
    const authHeader = await getTokenHeader();

    if (!readMessages.includes(id)) {
        readMessages.push(id);
        DeviceEventEmitter.emit('tabRead');

        return await fetch(`${baseUrl}/api/message/read?message_id=${encodeURIComponent(id)}`, {
            method: 'PUT',
            headers: { ...jsonHeaders, ...authHeader }
        });
    }
};

export default {
    sendImage,
    getMessages,
    getChats,
    getChat,
    read,
    sendMessage
};
