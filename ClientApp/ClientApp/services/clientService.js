import * as KeyChain from 'react-native-keychain';
import env from '../env';

const baseUrl = env.client_url || env.api_url;

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

const parsePhotoUris = (photoUris) => {
    if (!photoUris) {
        return ['', '', ''];
    }

    if (Array.isArray(photoUris)) {
        return [...photoUris, '', '', ''].slice(0, 3);
    }

    if (typeof photoUris === 'string') {
        try {
            const parsed = JSON.parse(photoUris);
            if (Array.isArray(parsed)) {
                return [...parsed, '', '', ''].slice(0, 3);
            }
        } catch (_) {
            return [photoUris, '', ''];
        }
    }

    return ['', '', ''];
};

const toBool = (value) => value === true || value === 'true' || value === 1 || value === '1';

const mapClient = (raw) => {
    if (!raw) {
        return null;
    }

    return {
        id: raw.id,
        guid: raw.guid,
        name: raw.name,
        surname: raw.surname,
        email: raw.email,
        phoneNumber: raw.phoneNumber || raw.phone_number || '',
        city: raw.city || '',
        street: raw.street || '',
        coordinates: raw.coordinates || '',
        iconUri: raw.iconUri || raw.icon_uri || '',
        averageGrade: raw.averageGrade ?? raw.average_grade ?? 0,
        reviewCount: raw.reviewCount ?? raw.review_count ?? 0
    };
};

const mapOrderRequest = (raw) => {
    if (!raw) {
        return null;
    }

    const rawClient = raw.client || {};

    return {
        id: raw.id,
        clientId: raw.clientId ?? raw.client_id,
        categoryId: raw.categoryId ?? raw.category_id,
        description: raw.description || '',
        searchRadius: raw.searchRadius ?? raw.search_radius ?? 0,
        toKnowPrice: toBool(raw.toKnowPrice ?? raw.to_know_price),
        toKnowDeadline: toBool(raw.toKnowDeadline ?? raw.to_know_deadline),
        toKnowEnrollmentDate: toBool(raw.toKnowEnrollmentDate ?? raw.to_know_enrollment_date),
        creationDate: raw.creationDate || raw.creation_date || '',
        photoUris: parsePhotoUris(raw.photoUris ?? raw.photo_uris),
        status: raw.status ?? 0,
        companiesWatched: raw.companiesWatched || raw.companies_watched || [],
        client: {
            userId: rawClient.userId || rawClient.user_id || rawClient.guid || '',
            guid: rawClient.guid || '',
            name: rawClient.name || '',
            surname: rawClient.surname || '',
            iconUri: rawClient.iconUri || rawClient.icon_uri || '',
            averageGrade: rawClient.averageGrade ?? rawClient.average_grade ?? 0,
            finishedOrdersCount: rawClient.finishedOrdersCount ?? rawClient.finished_orders_count ?? 0
        }
    };
};

const toClientPayload = (state = {}) => ({
    name: state.name || '',
    surname: state.surname || '',
    email: state.email || '',
    phone_number: state.phone_number || state.phoneNumber || '',
    city: state.city || '',
    street: state.street || ''
});

const toOrderPayload = (state = {}) => ({
    id: state.id,
    category_id: state.category_id ?? state.categoryId,
    description: state.description || '',
    search_radius: state.search_radius ?? state.searchRadius ?? 0,
    to_know_price: Boolean(state.to_know_price ?? state.toKnowPrice),
    to_know_deadline: Boolean(state.to_know_deadline ?? state.toKnowDeadline),
    to_know_enrollment_date: Boolean(state.to_know_enrollment_date ?? state.toKnowEnrollmentDate),
    photo_uris: state.photo_uris ?? state.photoUris ?? []
});

const get = async () => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/client/get`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapClient(await parseJsonSafe(response));
};

const getAdmin = async (guid) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/client/getClientAdmin?guid=${encodeURIComponent(guid)}`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapClient(await parseJsonSafe(response));
};

const getOrderRequest = async (categoriesId = []) => {
    const authHeader = await getTokenHeader();
    const queryArray = categoriesId.map((id, i) => `categoriesId[${i}]=${encodeURIComponent(id)}`);
    const query = queryArray.length > 0 ? `?${queryArray.join('&')}` : '';

    const response = await fetch(`${baseUrl}/api/client/getOrderRequests${query}`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });

    const json = await parseJsonSafe(response);
    const list = Array.isArray(json) ? json : [];
    return list.map(mapOrderRequest);
};

const sendOrderRequest = async (orderRequest) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/client/sendOrderRequest`, {
        method: 'POST',
        body: JSON.stringify(toOrderPayload(orderRequest)),
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapOrderRequest(await parseJsonSafe(response));
};

const getOrder = async (id) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/client/getRequest?request_id=${encodeURIComponent(id)}`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapOrderRequest(await parseJsonSafe(response));
};

const changeOrderRequest = async (orderRequest) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/client/changeOrderRequest`, {
        method: 'PUT',
        body: JSON.stringify(toOrderPayload(orderRequest)),
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapOrderRequest(await parseJsonSafe(response));
};

const getClientRequests = async () => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/client/getClientRequests`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });
    const json = await parseJsonSafe(response);
    const list = Array.isArray(json) ? json : [];
    return list.map(mapOrderRequest);
};

const changeIconUri = async (iconUri) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/client/changeIconUri?uri=${encodeURIComponent(iconUri)}`, {
        method: 'PUT',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapClient(await parseJsonSafe(response));
};

const changeIconUriAdmin = async (id, iconUri) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/client/changeIconUriAdmin?guid=${encodeURIComponent(id)}&uri=${encodeURIComponent(iconUri)}`, {
        method: 'PUT',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapClient(await parseJsonSafe(response));
};

const changeUserData = async (state) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/client/changeUserData`, {
        method: 'PUT',
        body: JSON.stringify(toClientPayload(state)),
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapClient(await parseJsonSafe(response));
};

const changeUserDataAdmin = async (state) => {
    const authHeader = await getTokenHeader();
    const guid = state.guid || state.id;
    const response = await fetch(`${baseUrl}/api/client/changeUserDataAdmin?guid=${encodeURIComponent(guid)}`, {
        method: 'PUT',
        body: JSON.stringify(toClientPayload(state)),
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapClient(await parseJsonSafe(response));
};

const getAll = async () => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/client/getClients`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });
    const json = await parseJsonSafe(response);
    const list = Array.isArray(json) ? json : [];
    return list.map(mapClient);
};

const deleteClient = async (id) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${baseUrl}/api/client/deleteClientAdmin?guid=${encodeURIComponent(id)}`, {
        method: 'DELETE',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return response.status;
};

export default {
    get,
    getAdmin,
    getAll,
    getOrder,
    sendOrderRequest,
    getClientRequests,
    changeOrderRequest,
    changeIconUri,
    changeIconUriAdmin,
    changeUserData,
    changeUserDataAdmin,
    getOrderRequest,
    deleteClient
};
