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

const mapCompany = (raw) => {
    if (!raw) {
        return null;
    }

    const categoriesId = raw.categoriesId || raw.categories_id || [];
    const socialMedias = raw.socialMedias || raw.social_medias || [];
    const photoUris = raw.photoUris || raw.photo_uris || [];
    const siteUrl = raw.siteUrl || raw.site_url || '';

    const isDataFilled = raw.isDataFilled ?? raw.is_data_filled ??
        Boolean(siteUrl || socialMedias.some((s) => s) || photoUris.some((p) => p) || categoriesId.length > 0);

    return {
        id: raw.id,
        guid: raw.guid,
        title: raw.title || '',
        phoneNumber: raw.phoneNumber || raw.phone_number || '',
        email: raw.email || '',
        iconUri: raw.iconUri || raw.icon_uri || '',
        siteUrl,
        address: raw.address || { city: raw.city || '', street: raw.street || '' },
        coords: raw.coords || raw.coordinates || '',
        distance: raw.distance ?? 0,
        averageGrade: raw.averageGrade ?? raw.average_grade ?? 0,
        socialMedias,
        photoUris,
        categoriesId,
        prepaymentAvailable: raw.prepaymentAvailable ?? raw.prepayment_available ?? false,
        prepayment: raw.prepayment ?? raw.prepayment_available ?? false,
        reviewCount: raw.reviewCount ?? raw.reviews_count ?? 0,
        description: raw.description || '',
        cardColor: raw.cardColor || raw.card_color || '#2196F3',
        isDataFilled
    };
};

const toChangeDataPayload = (data = {}) => ({
    title: data.title || '',
    phone_number: data.phone_number || data.phoneNumber || '',
    email: data.email || '',
    site_url: data.site_url || data.siteUrl || '',
    city: data.city || '',
    street: data.street || '',
    social_medias: data.social_medias || data.socialMedias || [],
    photo_uris: data.photo_uris || data.photoUris || [],
    categories_id: data.categories_id || data.categoriesId || [],
    description: data.description || '',
    card_color: data.card_color || data.cardColor || '#2196F3'
});

const toChangeDataAdminPayload = (data = {}) => ({
    guid: data.guid || data.id,
    ...toChangeDataPayload(data)
});

const toFillPayload = (data = {}) => ({
    site_url: data.site_url || data.siteUrl || '',
    social_medias: data.social_medias || data.socialMedias || [],
    photo_uris: data.photo_uris || data.photoUris || [],
    categories_id: data.categories_id || data.categoriesId || [],
    prepayment_available: data.prepayment_available ?? data.prepaymentAvailable ?? false,
    description: data.description || '',
    card_color: data.card_color || data.cardColor || null
});

const get = async () => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/company/get`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapCompany(await parseJsonSafe(response));
};

const getAdmin = async (id) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/company/getCompanyAdmin?guid=${encodeURIComponent(id)}`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapCompany(await parseJsonSafe(response));
};

const fillCompanyData = async (data) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/company/fillCompanyData`, {
        method: 'PUT',
        body: JSON.stringify(toFillPayload(data)),
        headers: { ...jsonHeaders, ...authHeader }
    });
    return response.status;
};

const getCompany = async (guid) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/company/getCompany?guid=${encodeURIComponent(guid)}`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapCompany(await parseJsonSafe(response));
};

const getAll = async () => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/company/getAll`, {
        method: 'GET',
        headers: { ...jsonHeaders, ...authHeader }
    });
    const json = await parseJsonSafe(response);
    const list = Array.isArray(json) ? json : [];
    return list.map(mapCompany);
};

const changeData = async (data) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/company/changeData`, {
        method: 'PUT',
        body: JSON.stringify(toChangeDataPayload(data)),
        headers: { ...jsonHeaders, ...authHeader }
    });
    return response.status;
};

const changeDataAdmin = async (data) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/company/changeDataAdmin`, {
        method: 'PUT',
        body: JSON.stringify(toChangeDataAdminPayload(data)),
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapCompany(await parseJsonSafe(response));
};

const changeIconUri = async (iconUri) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/company/changeIconUri?uri=${encodeURIComponent(iconUri)}`, {
        method: 'PUT',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapCompany(await parseJsonSafe(response));
};

const changeIconUriAdmin = async (guid, iconUri) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/company/changeIconUriAdmin?guid=${encodeURIComponent(guid)}&uri=${encodeURIComponent(iconUri)}`, {
        method: 'PUT',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapCompany(await parseJsonSafe(response));
};

const deleteCompany = async (id) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/company/delete?guid=${encodeURIComponent(id)}`, {
        method: 'DELETE',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return response.status;
};

export default {
    changeIconUri,
    changeIconUriAdmin,
    changeData,
    changeDataAdmin,
    get,
    getAdmin,
    fillCompanyData,
    getCompany,
    getAll,
    deleteCompany
};
