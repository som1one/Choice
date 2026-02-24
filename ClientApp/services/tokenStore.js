let token = '';

const set = (newToken) => {
    token = newToken;
}   

const get = () => {
    return token;
}

export default {
    set,
    get
}