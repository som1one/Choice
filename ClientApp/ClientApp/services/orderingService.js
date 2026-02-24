import * as KeyChain from 'react-native-keychain';
import env from '../env';

const createOrder = async (order) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Order/Create`, {
        method: 'POST',
        body: JSON.stringify(order),
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

const changeOrderEnrollmentDate = async (orderId, newDate) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Order/ChangeOrderEnrollmentDate?orderId=${orderId}&newDate=${newDate}`, {
        method: 'PUT',
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

const confirmDate = async (orderId) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Order/ConfirmEnrollmentDate?orderId=${orderId}`, {
        method: 'PUT',
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

const enroll = async (orderId) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Order/Enroll?orderId=${orderId}`, {
        method: 'PUT',
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

const finish = async (orderId) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Order/Finish?orderId=${orderId}`, {
        method: 'PUT',
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

const cancel = async (orderId) => {
    const token = await KeyChain.getGenericPassword();

    return await fetch(`${env.api_url}/api/Order/Cancel?orderId=${orderId}`, {
        method: 'PUT',
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
    createOrder,
    changeOrderEnrollmentDate,
    confirmDate,
    enroll,
    finish,
    cancel
}