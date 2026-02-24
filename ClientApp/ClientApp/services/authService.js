import * as KeyChain from 'react-native-keychain';
import { jwtDecode } from 'jwt-decode';
import { decode } from "base-64";
import env from '../env';
import tokenStore from './tokenStore';

global.atob = decode;

const register = async (name, email, phone, street, city, password, userType) => {
    const token = tokenStore.get();
    
    return await fetch(`${env.auth_url}/api/Auth/Register?email=${email}&password=${password}&name=${name}&phoneNumber=${phone}&street=${street}&city=${city}&type=${userType}&deviceToken=${token}`, {
        method: 'POST',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json'
        }
    })
    .then(async response => {
        let json = await response.json();

        return [response.status, json]
    })
    .catch(error => {
        console.log(error);
    });
}

const loginByEmail = async (email, password) => {
    const token = tokenStore.get();

    return await fetch(`${env.auth_url}/api/Auth/Login?email=${email}&password=${password}&deviceToken=${token}`, {
        method: 'POST',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json'
        }
    })
    .then(async response => {
        if (response.status == 200) {
            const json = await response.json();
            await KeyChain.setGenericPassword('api_key', json);
            const jsonDecoded = jwtDecode(json);
            console.log(json);
            if (jsonDecoded.type == 'Client') {
                return 1;
            }

            if (jsonDecoded.type == 'Company') {
                return 2;
            }

            return 3;
        }
        
        return -1;
    })
    .catch(error => {
        return [500, error];
    });
}

const loginByPhone = async (phone) => {
    return await fetch(`${env.auth_url}/api/Auth/LoginByPhone?phone=${phone}`, {
        method: 'POST',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json'
        }
    })
    .then(response => response.status == 200)
    .catch(error => {
        return [500, error];
    });
}

const verifyCode = async (phone, code) => {
    return await fetch(`${env.auth_url}/api/Auth/Verify?phone=${phone}&code=${code}`, {
        method: 'POST',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json'
        }
    })
    .then(async response => {
        if (response.status == 200) {
            const json = await response.json();
            await KeyChain.setGenericPassword('api_key', json);
            const jsonDecoded = jwtDecode(json);
            console.log(json);
            if (jsonDecoded.type == 'Client') {
                return 1;
            }

            if (jsonDecoded.type == 'Company') {
                return 2;
            }

            return 3;
        }
        
        return -1;
    })
    .catch(error => {
        return [500, error];
    });
}

const changePassword = async (currentPassword, newPassword) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.auth_url}/api/Auth/ChangePassword?currentPassword=${currentPassword}&newPassword=${newPassword}`, {
        method: 'PUT',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async res => {
        let json = await res.json();

        return [res.status, json];
    })
    .catch(error => {
        return [500, error];
    });
}

const resetPassword = async (email) => {
    return await fetch(`${env.auth_url}/api/Auth/ResetPassword?email=${email}`, {
        method: 'POST',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
        }
    })
    .then(res => {
        return res.status;
    })
    .catch(error => {
    });
}

const verifyPasswordReset = async (email, code) => {
    return await fetch(`${env.auth_url}/api/Auth/VerifyPasswordReset?email=${email}&code=${code}`, {
        method: 'POST',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
        }
    })
    .then(async res => {
        if (res.status == 200) {
            const token = await res.json();
            return [res.status, token]
        }

        return [res.status, ''];
    })
    .catch(error => {
    });
}

const setNewPassword = async (password, token) => {
    return await fetch(`${env.auth_url}/api/Auth/SetNewPassword?password=${password}`, {
        method: 'PUT',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        }
    })
    .then(async res => {
        return res.status;
    })
    .catch(error => {
    });
}

export default {
    loginByEmail,
    loginByPhone,
    verifyCode,
    changePassword,
    register,
    resetPassword,
    verifyPasswordReset,
    setNewPassword
}