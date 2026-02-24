import categoryService from "./categoryService.js";
import blobService from "./blobService.js";

let categories = [];

const getCategories = () => {
    return categories;
}

const retrieveData = async () => {
    categories = await categoryService.getCategories();
}

export default {
    getCategories,
    retrieveData
}