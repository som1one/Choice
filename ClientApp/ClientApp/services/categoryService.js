import * as KeyChain from 'react-native-keychain';
import env from '../env';

const getCategories = async () => {
    const token = await KeyChain.getGenericPassword();
    
    return await fetch(`${env.api_url}/api/Category/Get`, {
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
            iconUri: json[i].iconUri,
            title: json[i].title,
            id: json[i].id
        }));
    })
    .catch(error => {
        console.log(error);
    });
}

const create = async (body) => {
    const token = await KeyChain.getGenericPassword();
    
    return await fetch(`${env.api_url}/api/Category/Create`, {
        method: 'POST',
        body: JSON.stringify(body),
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(response => response.status)
    .catch(error => {
        console.log(error);
    });
}

const update = async (body) => {
    const token = await KeyChain.getGenericPassword();
    
    return await fetch(`${env.api_url}/api/Category/Update`, {
        method: 'PUT',
        body: JSON.stringify(body),
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(response => response.status)
    .catch(error => {
        console.log(error);
    });
}

const remove = async (id) => {
    const token = await KeyChain.getGenericPassword();
    
    return await fetch(`${env.api_url}/api/Category/Delete?id=${id}`, {
        method: 'DELETE',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(response => response.status)
    .catch(error => {
        console.log(error);
    });
}

export default {
    create,
    update,
    getCategories,
    remove
}