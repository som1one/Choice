import clientService from "./clientService";
import companyService from "./companyService";

let user;
let currentUserType;

const get = () => {
    return user;
}

const getUserType = () => {
    return currentUserType;
}

const retrieveData = async (userType) => {
    if (userType == 1) {
        user = await clientService.get();
        currentUserType = 1;
    }

    if (userType == 2) {
        user = await companyService.get();
        currentUserType = 2;
    }
}

const logout = () => {
    user = null;
    currentUserType = 0;
}

export default {
    retrieveData,
    logout,
    get,
    getUserType
}