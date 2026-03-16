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

const mapOrder = (raw) => {
    if (!raw) {
        return null;
    }

    return {
        id: raw.id,
        orderRequestId: raw.orderRequestId ?? raw.order_request_id,
        clientId: raw.clientId ?? raw.client_id,
        companyId: raw.companyId ?? raw.company_id,
        price: raw.price ?? 0,
        prepayment: raw.prepayment ?? 0,
        deadline: raw.deadline ?? 0,
        enrollmentDate: raw.enrollmentDate || raw.enrollment_date || null,
        isEnrolled: raw.isEnrolled ?? raw.is_enrolled ?? false,
        isDateConfirmed: raw.isDateConfirmed ?? raw.is_date_confirmed ?? false,
        status: raw.status ?? 0,
        userChangedEnrollmentDateGuid: raw.userChangedEnrollmentDateGuid || raw.user_changed_enrollment_date_guid || null
    };
};

const createOrder = async (order) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/order/create`, {
        method: 'POST',
        body: JSON.stringify({
            receiver_id: order.receiver_id || order.receiverId,
            order_request_id: order.order_request_id || order.orderRequestId,
            price: order.price ?? 0,
            prepayment: order.prepayment ?? 0,
            deadline: order.deadline ?? 0,
            enrollment_date: order.enrollment_date || order.enrollmentDate || order.enrollmentTime || null
        }),
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapOrder(await parseJsonSafe(response));
};

const changeOrderEnrollmentDate = async (orderId, newDate) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/order/changeOrderEnrollmentDate`, {
        method: 'PUT',
        body: JSON.stringify({
            order_id: orderId,
            enrollment_date: newDate
        }),
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapOrder(await parseJsonSafe(response));
};

const confirmDate = async (orderId) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/order/confirmEnrollmentDate?order_id=${encodeURIComponent(orderId)}`, {
        method: 'PUT',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapOrder(await parseJsonSafe(response));
};

const enroll = async (orderId) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/order/enroll?order_id=${encodeURIComponent(orderId)}`, {
        method: 'PUT',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapOrder(await parseJsonSafe(response));
};

const finish = async (orderId) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/order/finishOrder?order_id=${encodeURIComponent(orderId)}`, {
        method: 'PUT',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapOrder(await parseJsonSafe(response));
};

const cancel = async (orderId) => {
    const authHeader = await getTokenHeader();
    const response = await fetch(`${env.api_url}/api/order/cancelEnrollment?order_id=${encodeURIComponent(orderId)}`, {
        method: 'PUT',
        headers: { ...jsonHeaders, ...authHeader }
    });
    return mapOrder(await parseJsonSafe(response));
};

export default {
    createOrder,
    changeOrderEnrollmentDate,
    confirmDate,
    enroll,
    finish,
    cancel
};
