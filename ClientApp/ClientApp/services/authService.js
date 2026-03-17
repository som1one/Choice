import * as KeyChain from 'react-native-keychain';
import { jwtDecode } from 'jwt-decode';
import { decode } from 'base-64';
import env from '../env';
import tokenStore from './tokenStore';

global.atob = decode;

const jsonHeaders = {
    Accept: 'application/json',
    'Content-Type': 'application/json'
};

const parseJsonSafe = async (response) => {
    try {
        return await response.json();
    } catch (_) {
        return null;
    }
};

const extractToken = (payload) => {
    if (!payload) {
        return '';
    }

    if (typeof payload === 'string') {
        return payload;
    }

    return payload.access_token || payload.accessToken || payload.token || payload.reset_token || payload.resetToken || '';
};

const resolveUserType = (token) => {
    try {
        const decoded = jwtDecode(token);
        const value = decoded.user_type || decoded.type;

        if (value === 'Client') {
            return 1;
        }

        if (value === 'Company') {
            return 2;
        }

        return 3;
    } catch (_) {
        return -1;
    }
};

const normalizeRegisterType = (userType) => {
    if (userType === 1 || userType === '1') {
        return 'Client';
    }

    if (userType === 2 || userType === '2') {
        return 'Company';
    }

    if (typeof userType === 'string') {
        return userType;
    }

    return 'Client';
};

const normalizeRegisterResponse = (payload) => {
    if (!payload) {
        return payload;
    }

    if (payload.errors) {
        return payload;
    }

    const detail = payload.detail;
    if (!detail || typeof detail !== 'string') {
        return payload;
    }

    try {
        const normalized = detail
            .replaceAll("'", '"')
            .replace('phone_number', 'phoneNumber');
        const parsed = JSON.parse(normalized);
        return { ...payload, errors: parsed };
    } catch (_) {
        return payload;
    }
};

const register = async (name, email, phone, street, city, password, userType) => {
    const token = tokenStore.get();
    const body = {
        name,
        email,
        password,
        street,
        city,
        type: normalizeRegisterType(userType),
        device_token: token || null
    };

    if (phone && `${phone}`.trim() !== '') {
        body.phone_number = phone;
    }

    try {
        const response = await fetch(`${env.auth_url}/api/auth/register`, {
            method: 'POST',
            headers: jsonHeaders,
            body: JSON.stringify(body)
        });
        const json = normalizeRegisterResponse(await parseJsonSafe(response));
        return [response.status, json];
    } catch (error) {
        return [500, { error: error?.message || 'Network error' }];
    }
};

const loginByEmail = async (email, password) => {
    const deviceToken = tokenStore.get();

    try {
        const response = await fetch(`${env.auth_url}/api/auth/login`, {
            method: 'POST',
            headers: jsonHeaders,
            body: JSON.stringify({
                email,
                password,
                device_token: deviceToken || null
            })
        });

        if (response.status !== 200) {
            return -1;
        }

        const payload = await parseJsonSafe(response);
        const token = extractToken(payload);

        if (!token) {
            return -1;
        }

        await KeyChain.setGenericPassword('api_key', token);
        return resolveUserType(token);
    } catch (error) {
        return [500, error];
    }
};

const loginByPhone = async (phone) => {
    try {
        const response = await fetch(`${env.auth_url}/api/auth/loginByPhone`, {
            method: 'POST',
            headers: jsonHeaders,
            body: JSON.stringify({ phone })
        });
        return response.status === 200;
    } catch (_) {
        return false;
    }
};

const verifyCode = async (phone, code) => {
    try {
        const response = await fetch(`${env.auth_url}/api/auth/verify`, {
            method: 'POST',
            headers: jsonHeaders,
            body: JSON.stringify({ phone, code })
        });

        if (response.status !== 200) {
            return -1;
        }

        const payload = await parseJsonSafe(response);
        const token = extractToken(payload);

        if (!token) {
            return -1;
        }

        await KeyChain.setGenericPassword('api_key', token);
        return resolveUserType(token);
    } catch (error) {
        return [500, error];
    }
};

const changePassword = async (currentPassword, newPassword) => {
    const token = await KeyChain.getGenericPassword();

    if (!token || !token.password) {
        return [401, { error: 'Unauthorized' }];
    }

    try {
        const response = await fetch(`${env.auth_url}/api/auth/changePassword`, {
            method: 'PUT',
            headers: {
                ...jsonHeaders,
                Authorization: `Bearer ${token.password}`
            },
            body: JSON.stringify({
                current_password: currentPassword,
                new_password: newPassword
            })
        });
        const json = await parseJsonSafe(response);
        return [response.status, json];
    } catch (error) {
        return [500, error];
    }
};

const resetPassword = async (email) => {
    try {
        const response = await fetch(`${env.auth_url}/api/auth/resetPassword`, {
            method: 'POST',
            headers: jsonHeaders,
            body: JSON.stringify({ email })
        });
        return response.status;
    } catch (_) {
        return 500;
    }
};

const verifyPasswordReset = async (email, code) => {
    try {
        const response = await fetch(`${env.auth_url}/api/auth/verifyPasswordReset`, {
            method: 'POST',
            headers: jsonHeaders,
            body: JSON.stringify({ email, code })
        });

        const payload = await parseJsonSafe(response);
        const token = extractToken(payload);

        if (response.status === 200) {
            return [response.status, token];
        }

        return [response.status, ''];
    } catch (_) {
        return [500, ''];
    }
};

const setNewPassword = async (password, token) => {
    try {
        const response = await fetch(`${env.auth_url}/api/auth/setNewPassword`, {
            method: 'PUT',
            headers: {
                ...jsonHeaders,
                Authorization: `Bearer ${token}`
            },
            body: JSON.stringify({ password })
        });
        return response.status;
    } catch (_) {
        return 500;
    }
};

export default {
    loginByEmail,
    loginByPhone,
    verifyCode,
    changePassword,
    register,
    resetPassword,
    verifyPasswordReset,
    setNewPassword
};
