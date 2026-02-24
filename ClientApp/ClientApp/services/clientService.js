import * as KeyChain from 'react-native-keychain';
import { advanceAnimationByFrame } from 'react-native-reanimated';
import arrayHelper from '../helpers/arrayHelper';
import env from '../env';

const get = async () => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Client/GetClient`, {
        method: 'GET',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async response => await response.json())
    .catch(err => console.log(err));
}

const getAdmin = async (id) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Client/GetClientAdmin?id=${id}`, {
        method: 'GET',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async response => await response.json())
    .catch(err => console.log(err));
}

const getOrderRequest = async (categoriesId) => {
    const token = await KeyChain.getGenericPassword()
    
    let queryArray = categoriesId.map((id, i) => `categoriesId[${i}]=${id}`);

    return await fetch(`${env.api_url}/api/Client/GetOrderRequests?${queryArray.join('&')}`, {
        method: 'GET',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async response => await response.json());
}

const sendOrderRequest = async (orderRequest) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Client/SendOrderRequest`, {
        method: 'POST',
        body: JSON.stringify(orderRequest),
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async response => {
        const json = await response.json();

        return {
            categoryId: json.categoryId,
            creationDate: json.creationDate.toString(),
            description: json.description,
            id: json.id,
            searchRadius: json.searchRadius,
            status: json.status,
            toKnowDeadline: json.toKnowDeadline,
            toKnowEnrollmentDate: json.toKnowEnrollmentDate,
            toKnowPrice: json.toKnowPrice,
            photoUris: [json.photoUris[0], json.photoUris[1], json.photoUris[2]]
        };
    });
}

const getOrder = async (id) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Client/GetOrderRequest?id=${id}`, {
        method: 'GET',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async response => await response.json());
}

const changeOrderRequest = async (orderRequest) => {
    const token = await KeyChain.getGenericPassword();
    
    return await fetch(`${env.api_url}/api/Client/ChangeOrderRequest`, {
        method: 'PUT',
        body: JSON.stringify(orderRequest),
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async response => {
        const json = await response.json();

        return {
            categoryId: json.categoryId,
            creationDate: json.creationDate.toString(),
            description: json.description,
            id: json.id,
            searchRadius: json.searchRadius,
            status: json.status,
            toKnowDeadline: json.toKnowDeadline,
            toKnowEnrollmentDate: json.toKnowEnrollmentDate,
            toKnowPrice: json.toKnowPrice,
            photoUris: [json.photoUris[0], json.photoUris[1], json.photoUris[2]]
        };
    });
}

const getClientRequests = async () => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Client/GetClientRequests`, {
        method: 'GET',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async response => {
        const json = await response.json();

        return Object.keys(json).map((i) => ({
            id: json[i].id,
            status: json[i].status,
            description: json[i].description,
            categoryId: json[i].categoryId,
            searchRadius: json[i].searchRadius,
            toKnowPrice: json[i].toKnowPrice,
            toKnowDeadline: json[i].toKnowDeadline,
            toKnowEnrollmentDate: json[i].toKnowEnrollmentDate,
            creationDate: json[i].creationDate,
            photoUris: [json[i].photoUris[0], json[i].photoUris[1], json[i].photoUris[2]]
        }));
    });
}

const changeIconUri = async (iconUri) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Client/ChangeIconUri?iconUri=${iconUri}`, {
        method: 'PUT',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async res => await res.json());
}

const changeIconUriAdmin = async (id, iconUri) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Client/ChangeIconUriAdmin?id=${id}&iconUri=${iconUri}`, {
        method: 'PUT',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async res => await res.json());
}

const changeUserData = async (state) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Client/ChangeUserData`, {
        method: 'PUT',
        body: JSON.stringify(state),
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async res => await res.json());
}

const changeUserDataAdmin = async (state) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Client/ChangeUserDataAdmin`, {
        method: 'PUT',
        body: JSON.stringify(state),
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async res => await res.json());
}

const getAll = async () => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Client/Get`, {
        method: 'GET',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async res => await res.json());
}

const deleteClient = async (id) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Client/Delete?id=${id}`, {
        method: 'DELETE',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async res => res.status);
}

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
}