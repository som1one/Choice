
const validateInstagramUrl = (url) => {
    const regex = new RegExp(/https?:\/\/(www\.)?instagram\.com\/[a-z\d]{1,255}(\/)?/i);

    return regex.test(url);
}

const validateVkUrl = (url) => {
    const regex = new RegExp(/https?:\/\/(www\.)?vk\.com\/[a-z\d]{1,255}(\/)?/i);

    return regex.test(url);
}

const validateFacebookUrl = (url) => {
    const regex = new RegExp(/https?:\/\/(www\.)?facebook\.com\/[a-z\d]{1,255}(\/)?/i);

    return regex.test(url);
}

const validateTgUrl = (url) => {
    const regex = new RegExp(/https?:\/\/(www\.)?t\.me\/.{1,255}(\/)?/i);

    return regex.test(url);
}

export default {
    validateInstagramUrl,
    validateFacebookUrl,
    validateVkUrl,
    validateTgUrl
}