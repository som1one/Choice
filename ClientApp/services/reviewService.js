import * as KeyChain from 'react-native-keychain';
import env from '../env';

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

const buildAuthorName = (raw) => {
    if (raw?.author?.name) {
        return raw.author.name;
    }

    const sender = raw?.sender_id || raw?.senderId || '';
    const short = sender ? String(sender).slice(0, 6) : 'user';
    return `User_${short}`;
};

const mapReview = (raw) => ({
    id: raw.id,
    text: raw.text || '',
    grade: raw.grade ?? 0,
    photoUris: raw.photoUris || raw.photo_uris || [],
    senderId: raw.senderId || raw.sender_id,
    receiverId: raw.receiverId || raw.receiver_id,
    author: {
        name: buildAuthorName(raw)
    }
});

const send = async (review) => {
    const authHeader = await getTokenHeader();

    const response = await fetch(`${env.api_url}/api/review/send`, {
        method: 'POST',
        body: JSON.stringify({
            guid: review.guid,
            text: review.text,
            grade: review.grade,
            photo_uris: review.photo_uris || review.photoUris || []
        }),
        headers: { ...jsonHeaders, ...authHeader }
    });

    return response.status;
};

const get = async (userGuid) => {
    const authHeader = await getTokenHeader();

    const response = await fetch(`${env.api_url}/api/review/get?guid=${encodeURIComponent(userGuid)}`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });

    const json = await parseJsonSafe(response);
    const list = Array.isArray(json) ? json : [];
    return list.map(mapReview);
};

export default {
    send,
    get
};
