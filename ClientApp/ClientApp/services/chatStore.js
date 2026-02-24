import chatService from "./chatService";

let chats = [];

const retrieveData = async () => {
    chats = await chatService.getChats();
}

const getChats = () => chats;

export default {
    retrieveData,
    getChats
}