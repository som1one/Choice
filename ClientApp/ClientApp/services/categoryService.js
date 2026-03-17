import * as KeyChain from 'react-native-keychain';
import env from '../env';

const baseUrl = env.category_url || env.api_url;

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

const mapCategory = (raw) => ({
    id: raw.id,
    title: raw.title,
    iconUri: raw.iconUri || raw.icon_uri || ''
});

const getCategories = async () => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/category/get`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });
    const json = await parseJsonSafe(response);
    const list = Array.isArray(json) ? json : [];
    return list.map(mapCategory);
};

const create = async (body) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/category/create`, {
        method: 'POST',
        body: JSON.stringify({
            title: body.title,
            icon_uri: body.icon_uri || body.iconUri || ''
        }),
        headers: { ...jsonHeaders, ...authHeader }
    });
    return response.status;
};

const update = async (body) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/category/update`, {
        method: 'PUT',
        body: JSON.stringify({
            id: body.id,
            title: body.title,
            icon_uri: body.icon_uri || body.iconUri || ''
        }),
        headers: { ...jsonHeaders, ...authHeader }
    });
    return response.status;
};

const remove = async (id) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/category/delete?category_id=${encodeURIComponent(id)}`, {
        method: 'DELETE',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return response.status;
};

export default {
    create,
    update,
    getCategories,
    remove
};
