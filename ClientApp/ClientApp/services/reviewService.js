import * as KeyChain from 'react-native-keychain';
import env from '../env';

const send = async (review) => {
    const token = await KeyChain.getGenericPassword();
    
    return await fetch(`${env.api_url}/api/Review/Send`, {
        method: 'POST',
        body: JSON.stringify(review),
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async response => console.log(response.status))
    .catch(err => {
        console.log(err);
    });
}

const get = async (userGuid) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Review/Get?guid=${userGuid}`, {
        method: 'GET',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token.password}`
        }
    })
    .then(async response => await response.json())
    .catch(err => {
        console.log(err);
    });
}

export default {
    send,
    get
}