import React from 'react';
import {
    View,
    FlatList,
    Text,
    RefreshControl,
    DeviceEventEmitter,
    TouchableOpacity,
    ScrollView
} from 'react-native';
import Chat from '../Components/Chat';
import chatStore from '../services/chatStore';
import chatService from '../services/chatService';
import { useIsFocused } from '@react-navigation/native';
import { Icon } from 'react-native-elements';
import styles from '../Styles';
import userStore from '../services/userStore';

export default function ChatsScreen({ navigation }) {
    const [chats, setChats] = React.useState([]);
    const [refreshing, setRefreshing] = React.useState(false);

    const isFocused = useIsFocused();

    const onRefresh = React.useCallback(async () => {
        setRefreshing(true);

        await chatStore.retrieveData();
        setChats(chatStore.getChats());

        setRefreshing(false);
    }, []);

    const handleMessage = async (message) => {
        if (isFocused) {
            let index = chats.findIndex(c => c.guid == message.senderId);
            if (index == -1) {
                let chat = await chatService.getChat(message.senderId);

                setChats(prev => {
                    prev.push(chat);
                    return [...prev];
                });
            } 
            else {
                setChats(prev => {
                    prev[index].messages.push(message);
                    return [...prev];
                });
            }
        }
    }
    
    const handleReadMessage = (message) => {
        let chatIndex = chats.findIndex(c => c.guid == message.receiverId);
        let messageIndex = chats[chatIndex].messages.findIndex(m => m.id == message.id);

        setChats(prev => {
            prev[chatIndex].messages[messageIndex].isRead = true;

            return [...prev];
        });
    }

    const handleEnrollmentDateChanged = async (message) => {
        if (isFocused) {
            let index = chats.findIndex(c => c.guid == message.senderId);
            if (index == -1) {
                let chat = await chatService.getChat(message.senderId);

                setChats(prev => {
                    prev.push(chat);
                    return [...prev];
                });
            } 
            else {
                setChats(prev => {
                    prev[index].messages.push(message);
                    return [...prev];
                });
            }
        }
    }

    const handleChatChanged = (user) => {
        
    }

    React.useEffect(() => {
        isFocused && onRefresh();
    }, [isFocused]);

    React.useEffect(() => {
        DeviceEventEmitter.addListener('messageReceived', handleMessage);
        DeviceEventEmitter.addListener('chatChanged', handleChatChanged);
        DeviceEventEmitter.addListener('read', handleReadMessage);
        DeviceEventEmitter.addListener('enrollmentDateChanged', handleEnrollmentDateChanged);

        return () => {
            DeviceEventEmitter.removeAllListeners('messageReceived');
            DeviceEventEmitter.removeAllListeners('chatChanged');
            DeviceEventEmitter.removeAllListeners('read');
            DeviceEventEmitter.removeAllListeners('enrollmentDateChanged');
        }
    }, [handleMessage,handleChatChanged,handleReadMessage,handleEnrollmentDateChanged]);

    return (
        <View style={{flex: 1, backgroundColor: 'white'}}>
            <Text
                style={{
                    fontWeight: '600',
                    fontSize: 21,
                    color: 'black',
                    paddingTop: 20,
                    alignSelf: 'center'
                }}>
                Чаты
            </Text>
            {
                chats.length > 0 ?
                <>
                    <FlatList
                        data={chats}
                        style={{paddingTop: 10}}
                        refreshControl={
                            <RefreshControl refreshing={refreshing} onRefresh={onRefresh}/>
                        }
                        renderItem={({item}) => {
                            return (
                                <View style={{paddingBottom: 5}}>
                                    <Chat chat={item} navigation={navigation}/>
                                </View>
                            )
                        }}/>
                </>
                :
                <>
                    <ScrollView 
                        refreshControl={
                            <RefreshControl refreshing={refreshing} onRefresh={onRefresh}/>
                        }>
                        <Icon 
                            size={60}
                            type='material'
                            name='sentiment-dissatisfied'
                            style={{paddingTop: 200}}
                            color='#3F8AE0'/>
                        <Text 
                            style={{
                                fontSize: 24, 
                                fontWeight: '700', 
                                color: 'black', 
                                alignSelf: 'center',
                                paddingTop: 30
                            }}>
                            Чатов нет
                        </Text>
                        <Text 
                            style={{
                                fontSize: 16, 
                                fontWeight: '400', 
                                color: '#818C99', 
                                alignSelf: 'center',
                                paddingTop: 20
                            }}>
                            Сообщений пока нет
                        </Text>
                        <View style={{paddingTop: 60, paddingHorizontal: 80}}>
                            <TouchableOpacity 
                                style={styles.button}
                                onPress={() => navigation.navigate(userStore.getUserType() == 1 ? 'Category' : 'Order')}>
                                <Text style={styles.buttonText}>
                                    {userStore.getUserType() == 1 ? 'Посмотреть услуги' : 'Посмотреть заказы'}
                                </Text>
                            </TouchableOpacity>
                        </View>    
                    </ScrollView>
                </>
            }
        </View>
    );
}