import React from 'react';
import {
    View,
    Dimensions,
    TouchableOpacity,
    Text,
    Image,
    RefreshControl,
    TextInput,
    DeviceEventEmitter
} from 'react-native';
import { Icon } from 'react-native-elements';
import { useIsFocused } from '@react-navigation/native';
import chatService from '../services/chatService';
import env from '../env';
import { FlatList } from 'react-native-gesture-handler';
import userStore from '../services/userStore';
import Message from '../Components/Message';
import dateHelper from '../helpers/dateHelper';
import DatePicker from 'react-native-date-picker';
import { Modalize } from 'react-native-modalize';
import styles from '../Styles';
import orderingService from '../services/orderingService';
import arrayHelper from '../helpers/arrayHelper';
import ImageBox from '../Components/ImageBox';
import reviewService from '../services/reviewService';
import messageStore from '../services/messageStore';
import categoryService from '../services/categoryService';
import CustomTextInput from '../Components/CustomTextInput';
import * as ImagePicker from 'react-native-image-picker';
import blobService from '../services/blobService';
import companyService from '../services/companyService';
import ReviewPage from '../Components/ReviewPage';
import CompanyPage from '../Components/CompanyPage';

const ChatScreen = ({ navigation, route }) => {
    const { chatId } = route.params;

    const [refreshing, setRefreshing] = React.useState(false);
    const [companyPageRefreshing, setCompanyPageRefreshing] = React.useState(false);
    const [fisrtImageUri, setFirstImageUri] = React.useState('');
    const [secondImageUri, setSecondImageUri] = React.useState('');
    const [thirdImageUri, setThirdImageUri] = React.useState('');
    const [readMessages, setReadMessages] = React.useState([]);
    const [grade, setGrade] = React.useState(1);
    const [chat, setChat] = React.useState({
        name: '',
        iconUri: '',
        guid: '',
        status: 1,
        lastTimeOnline: '',
        messages: []
    });
    const [lastTimeOnlineString, setLastTimeOnlineString] = React.useState('');
    const [messages, setMessages] = React.useState([]);
    const [mockId, setMockId] = React.useState(-1);
    const [text, setText] = React.useState('');
    const [company, setCompany] = React.useState('');
    const [client, setClient] = React.useState('');
    const enrollmentDateRef = React.useRef(null);
    const reviewsModalRef = React.useRef(null);
    const companyReviewModalRef = React.useRef(null);
    const modalRef = React.useRef(null);
    const [enrollmentDate, setEnrollmentDate] = React.useState(new Date());
    const { width, height } = Dimensions.get('screen');
    const [id, setId] = React.useState(-1);
    const [reviewBody, setReviewBody] = React.useState('');

    const isFocused = useIsFocused();

    const handleMessage = (message) => {
        if (isFocused) {
            setMessages(prev => {
                prev.push(message);
                return [...prev];
            })
        }
    }

    const sendImage = async () => {
        let response = await ImagePicker.launchImageLibrary();
        
        if (!response.didCancel) {
            let iconUri = await blobService.uploadImage(response.assets[0].uri);

            let message = await chatService.sendImage(iconUri, chat.guid);

            setMessages(prev => {
                prev.push(message);
                return [...prev];
            });
                            
            setText('');
        }
    }

    const handleEnrollmentChangedMessage = (message) => {
        if (isFocused) {
            let lastIndex = arrayHelper.lastOrDefault(messages, (m) => m.type == 3);

            setMessages(prev => {
                let body = JSON.parse(prev[lastIndex].body);
                body.IsActive = false;
                body.PastEnrollmentTime = body.EnrollmentTime;
                prev[lastIndex].body = JSON.stringify(body);

                prev.push(message);
                return [...prev];
            })
        }
    }

    const handleChangedMessage = (message) => {
        let index = arrayHelper.lastOrDefault(messages, m => JSON.parse(m.body).OrderId == JSON.parse(message.body).OrderId);

        setMessages(prev => {
            prev[index] = message;
            return [...prev];
        });
    }

    const handleChatChanged = (user) => {
        if (user.guid == chat.guid) {
            setChat(prev => {
                prev.status = user.status;
                prev.lastTimeOnline = user.lastTimeOnline;

                return prev;
            });
            setLastTimeOnlineString(user.status == 2 ? `Был(а) ${dateHelper.getDifference(user.lastTimeOnline)} назад` : 'В сети');
        }
    }

    const handleReadMessage = (message) => {
        let index = messages.findIndex(m => m.id == message.id);

        if (index != -1) {
            setMessages(prev => {
                prev[index].isRead = true;
    
                return [...prev];
            });
        }
    }

    const onReviewPressed = () => {
        modalRef.current?.close();

        companyReviewModalRef.current.open();
    }

    const getCompany = React.useCallback(async (companyId) => {
        setCompanyPageRefreshing(true);

        let company = await companyService.getCompany(companyId);
        setCompany(company);

        setCompanyPageRefreshing(false);
    }, [])

    React.useEffect(() => {
        DeviceEventEmitter.addListener('messageReceived', handleMessage);
        DeviceEventEmitter.addListener('messageChanged', handleChangedMessage);
        DeviceEventEmitter.addListener('enrollmentDateChanged', handleEnrollmentChangedMessage);
        DeviceEventEmitter.addListener('chatChanged', handleChatChanged);
        DeviceEventEmitter.addListener('read', handleReadMessage);

        return () => {
            DeviceEventEmitter.removeAllListeners('messageReceived');
            DeviceEventEmitter.removeAllListeners('messageChanged');
            DeviceEventEmitter.removeAllListeners('enrollmentDateChanged');
            DeviceEventEmitter.removeAllListeners('chatChanged');
            DeviceEventEmitter.removeAllListeners('read');
        };
    }, [handleMessage,handleChangedMessage,handleEnrollmentChangedMessage,handleReadMessage]);

    const enroll = async (id) => {
        let index = messages.findIndex(m => m.id == id);
        setMessages(prev => {
            let body = JSON.parse(prev[index].body);
            body.IsEnrolled = true;

            prev[index].body = JSON.stringify(body);

            return [...prev];
        });

        await orderingService.enroll(JSON.parse(messages[index].body).OrderId);
    }

    const changeStatus = async (id, status) => {
        let index = messages.findIndex(m => m.id == id);
        setMessages(prev => {
            let body = JSON.parse(prev[index].body);
            body.Status = status;

            prev[index].body = JSON.stringify(body);

            return [...prev];
        });

        if (status == 2) {
            await orderingService.finish(JSON.parse(messages[index].body).OrderId);
        }
        else {
            await orderingService.cancel(JSON.parse(messages[index].body).OrderId);
        }
    }
    
    const confirmDate = async (id) => {
        let index = messages.findIndex(m => m.id == id);

        let order = await orderingService.confirmDate(JSON.parse(messages[index].body).OrderId);

        setMessages(prev => {
            prev[index].body = JSON.stringify({
                OrderId: order.id,
                OrderRequestId: order.orderRequestId,
                Price: order.price,
                Prepayment: order.prepayment,
                Deadline: order.deadline,
                IsEnrolled: order.isEnrolled,
                EnrollmentTime: order.enrollmentDate,
                Status: order.status,
                IsActive: true,
                IsDateConfirmed: order.isDateConfirmed,
                UserChangedEnrollmentDate: order.userChangedEnrollmentDateGuid
            });

            return [...prev];
        });
    }

    const onRefresh = React.useCallback(async () => {
        setRefreshing(true);

        let chat = await chatService.getChat(chatId);
        setChat(chat);
        setLastTimeOnlineString(chat.status == 2 ? `Был(а) ${dateHelper.getDifference(chat.lastTimeOnline)} назад` : 'В сети');

        let messages = Object.keys(chat.messages).map((i) => ({
            id: chat.messages[i].id,
            receiverId: chat.messages[i].receiverId,
            senderId: chat.messages[i].senderId,
            creationTime: chat.messages[i].creationTime,
            body: chat.messages[i].body,
            type: chat.messages[i].type,
            isRead: chat.messages[i].isRead     
        }));

        setMessages(messages);

        messageStore.setMessages(messages);

        await userStore.retrieveData(userStore.getUserType());

        setRefreshing(false);
    }, []);

    const onViewableItemsChanged = React.useRef(async ({viewableItems, changed}) => {
        viewableItems.forEach(async i => {
            if (i.isViewable && i.item.receiverId == userStore.get().guid && !i.item.isRead) {
                await chatService.read(i.item.id);
            }
        });
    });

    const getGradeName = () => {
        let s = '';

        switch (grade) {
            case 1:
                s = 'Очень плохо'
                break;
            case 2:
                s = 'Плохо'
                break;
            case 3: 
                s = 'Нормально'
                break;
            case 4:
                s = 'Хорошо'
                break;
            case 5:
                s = 'Отлично'
                break; 
        }

        return s;
    }

    const viewabilityConfig = React.useRef({viewAreaCoveragePercentThreshold: 50});

    React.useEffect(() => {
        isFocused && onRefresh();
    }, [isFocused])

    return (
        <View
            style={{
                flex: 1, 
                justifyContent: 'center', 
                backgroundColor: '#F4F5FF'
            }}>
            <Modalize
                adjustToContentHeight={true}
                childrenStyle={{height: '100%'}}
                ref={companyReviewModalRef}>
                <View
                    style={{
                        flex: 1,
                        justifyContent: 'center',
                    }}>
                    <View
                        style={{
                            flexDirection: 'row',
                            justifyContent: 'space-between',
                            paddingTop: 10,
                            paddingHorizontal: 10
                        }}>
                        <Text></Text>
                        <Text
                            style={{
                                color: 'black',
                                fontWeight: '600',
                                fontSize: 21
                            }}>
                            Отзывы
                        </Text>
                        <TouchableOpacity
                            onPress={() => companyReviewModalRef.current?.close()}
                            style={{
                                borderRadius: 360,
                                backgroundColor: '#eff1f2',
                            }}>
                            <Icon 
                                name='close'
                                type='material'
                                size={27}
                                color='#818C99'/>
                        </TouchableOpacity>    
                    </View>
                    <ReviewPage
                        user={userStore.getUserType() == 1 ? company : client}/>
                </View>
            </Modalize>
            <Modalize 
                ref={modalRef}
                adjustToContentHeight={true}
                scrollViewProps={{nestedScrollEnabled: false, scrollEnabled: false}}
                childrenStyle={{height: '100%'}}>
                <View
                    style={{
                        flex: 1,
                        justifyContent: 'center',
                        paddingHorizontal: 10
                    }}>
                    <View
                        style={{
                            flexDirection: 'row',
                            justifyContent: 'space-between',
                            paddingTop: 10
                        }}>
                        <Text></Text>
                        <Text
                            style={{
                                color: 'black',
                                fontWeight: '600',
                                fontSize: 21
                            }}>
                            Компания
                        </Text>
                        <TouchableOpacity
                            onPress={() => modalRef.current?.close()}
                            style={{
                                borderRadius: 360,
                                backgroundColor: '#eff1f2',
                            }}>
                            <Icon 
                                name='close'
                                type='material'
                                size={27}
                                color='#818C99'/>
                        </TouchableOpacity>
                    </View>
                    <View
                        style={{
                            paddingTop: 10
                        }}>
                        {
                            refreshing ?
                            <>
                                <RefreshControl
                                    refreshing={companyPageRefreshing}
                                    onRefresh={getCompany}/>
                            </>
                            :
                            <>
                                <CompanyPage
                                    navigation={navigation}
                                    onReviewPressed={onReviewPressed}
                                    company={company}
                                    order={''}
                                    mapButton/>
                            </>
                        }    
                    </View>
                </View>
            </Modalize>
            <Modalize
                ref={reviewsModalRef}
                adjustToContentHeight
                childrenStyle={{height: '90%'}}>
                <View
                    style={{
                        flex: 1,
                        justifyContent: 'center',
                        paddingHorizontal: 20
                    }}>
                    <View
                        style={{
                            flexDirection: 'row',
                            justifyContent: 'space-between',
                            paddingTop: 10
                        }}>
                        <Text>
                        </Text>
                        <Text
                            style={{
                                color: 'black',
                                fontSize: 21,
                                fontWeight: 600,
                                alignSelf: 'center'
                            }}>
                            {userStore.getUserType() == 1 ? 'Отзыв о компании' : 'Отзыв о клиенте'} 
                        </Text>
                        <TouchableOpacity
                            style={{
                                alignSelf: 'center',
                                borderRadius: 360,
                                backgroundColor: '#EFF1F2'
                            }}
                            onPress={() => reviewsModalRef.current?.close()}>
                            <Icon
                                name='close'
                                type='material'
                                size={25}
                                color='#818C99'/>    
                        </TouchableOpacity>    
                    </View>
                    <Text
                        style={{
                            fontWeight: '600',
                            fontSize: 16,
                            color: 'black',
                            alignSelf: 'center',
                            paddingTop: 30
                        }}>
                        {getGradeName()}
                    </Text>
                    <View
                        style={{
                            flexDirection: 'row',
                            justifyContent: 'space-between',
                            paddingTop: 10
                        }}>
                        <TouchableOpacity
                            onPress={() => setGrade(1)}>
                            <Icon
                                type='material'
                                name='star'
                                color='#E4E839'
                                size={50}/>
                        </TouchableOpacity>
                        <TouchableOpacity
                            onPress={() => setGrade(2)}>
                            <Icon
                                type='material'
                                name='star'
                                color={grade >= 2 ? '#E4E839' : '#CFCFCF'}
                                size={50}/>
                        </TouchableOpacity>
                        <TouchableOpacity
                            onPress={() => setGrade(3)}>
                            <Icon
                                type='material'
                                name='star'
                                color={grade >= 3 ? '#E4E839' : '#CFCFCF'}
                                size={50}/>
                        </TouchableOpacity>
                        <TouchableOpacity
                            onPress={() => setGrade(4)}>
                            <Icon
                                type='material'
                                name='star'
                                color={grade >= 4 ? '#E4E839' : '#CFCFCF'}
                                size={50}/>
                        </TouchableOpacity>
                        <TouchableOpacity
                            onPress={() => setGrade(5)}>
                            <Icon
                                type='material'
                                name='star'
                                color={grade == 5 ? '#E4E839' : '#CFCFCF'}
                                size={50}/>
                        </TouchableOpacity>
                    </View>

                    <Text
                        style={{
                            color: '#6D7885',
                            fontSize: 14,
                            fontWeight: '400',
                            paddingBottom: 5,
                            paddingTop: 30
                        }}>
                        Отзыв
                    </Text>
                    <CustomTextInput
                        value={reviewBody}
                        big
                        changed={setReviewBody}
                        placeholder='Введите текст вашего отзыва'/>
                    <Text 
                        style={{
                            fontSize: 14, 
                            fontWeight: '400', 
                            color: '#6D7885',
                            paddingTop: 20, 
                            paddingBottom: 10
                        }}>
                        Приложите файлы к заказу
                    </Text>
                    <View style={{flexDirection: 'row', justifyContent: 'space-between'}}>
                        <ImageBox 
                            onUriChanged={(state) => { 
                                setFirstImageUri(state);
                            }}
                            uri={fisrtImageUri}/>
                        <ImageBox 
                            onUriChanged={(state) => { 
                                setSecondImageUri(state);
                            }}
                            uri={secondImageUri}/>
                        <ImageBox 
                            onUriChanged={(state) => { 
                                setThirdImageUri(state);
                            }}
                            uri={thirdImageUri}/>
                    </View>
                    <View
                        style={{paddingTop: 30}}>
                        <TouchableOpacity 
                            style={[styles.button, {
                                backgroundColor: reviewBody == '' ? '#ABCDf3' : '#2D81E0'
                            }]}
                            disabled={reviewBody == ''}
                            onPress={(reviewBody != '') && (async () => {
                                let index = messages.findIndex(m => m.id == id);
                                await reviewService.send({
                                    guid: userStore.get().guid != messages[index].senderId ? messages[index].senderId : messages[index].receiverId,
                                    text: reviewBody,
                                    grade,
                                    photoUris: [fisrtImageUri, secondImageUri, thirdImageUri]
                                });
                                reviewsModalRef.current?.close();
                            })}>
                            <Text style={styles.buttonText}>
                                Оставить отзыв
                            </Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </Modalize>
            <Modalize
                ref={enrollmentDateRef}
                adjustToContentHeight
                childrenStyle={{height: '70%'}}>
                <View
                    style={{
                        flex: 1, 
                        justifyContent: 'center',
                        paddingHorizontal: 20
                    }}>
                    <View
                        style={{
                            flexDirection: 'row', 
                            justifyContent: 'space-between',
                            paddingTop: 20
                        }}>
                        <Text></Text>
                        <Text
                            style={{
                                fontSize: 21,
                                fontWeight: '600',
                                color: 'black'
                            }}>
                            Выберите дату и время записи
                        </Text>
                        <TouchableOpacity
                            style={{
                                borderRadius: 360,
                                backgroundColor: '#eff1f2',
                            }}
                            onPress={() => {
                                enrollmentDateRef.current?.close();
                            }}>
                            <Icon
                                name='close'
                                type='material'
                                size={27}
                                color='#818C99'/>
                        </TouchableOpacity>
                    </View>
                    <View style={{paddingTop: 20}}>
                        <DatePicker
                            date={enrollmentDate}
                            mode="datetime"
                            style={{alignSelf: 'center'}}
                            onDateChange={setEnrollmentDate}/>
                    </View>
                    <View style={{paddingTop: 20}}>
                        <TouchableOpacity 
                            style={[styles.button]}
                            onPress={async () => {
                                let order = await orderingService.changeOrderEnrollmentDate(id, dateHelper.convertFullDateToJson(enrollmentDate));
                                setMessages(prev => {
                                    let index = arrayHelper.lastOrDefault(prev, m => {
                                        if (m.type == 3) {
                                            return JSON.parse(m.body).OrderId == id
                                        }

                                        return false;
                                    });

                                    let body = JSON.parse(prev[index].body);
                                    body.IsActive = false;
                                    body.PastEnrollmentTime = body.EnrollmentTime;
                                    prev[index].body = JSON.stringify(body);
                                    prev.push({
                                        id: mockId,
                                        body: JSON.stringify({
                                            OrderId: order.id,
                                            OrderRequestId: order.orderRequestId,
                                            Price: order.price,
                                            Prepayment: order.prepayment,
                                            Deadline: order.deadline,
                                            IsEnrolled: order.isEnrolled,
                                            EnrollmentTime: order.enrollmentDate,
                                            PastEnrollmentTime: body.EnrollmentTime,
                                            Status: order.status,
                                            IsActive: true,
                                            IsDateConfirmed: order.isDateConfirmed,
                                            UserChangedEnrollmentDate: order.userChangedEnrollmentDateGuid
                                        }),
                                        senderId: userStore.get().guid,
                                        receiverId: prev[index].receiverId != userStore.get().guid ? prev[index].receiverId : prev[index].senderId,
                                        type: 3,
                                        isRead: false,
                                        creationTime: dateHelper.convertFullDateToJson(new Date())
                                    });
                                    setMockId(prev => prev-1);
                                    return [...prev];
                                });
                                
                                enrollmentDateRef.current?.close();
                            }}>
                            <Text style={[styles.buttonText]}>
                                Выбрать
                            </Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </Modalize>
            <TouchableOpacity
                style={{
                    top: 0,
                    width,
                    position: messages.length > 0 ? 'relative' : 'absolute',
                    backgroundColor: 'white',
                    justifyContent: 'center'
                }}
                onPress={async () => {
                    if (userStore.getUserType() == 1) {
                        await getCompany(chat.guid);
                        modalRef.current.open();
                    }
                    else {

                    }
                }}>
                <View
                    style={{
                        flexDirection: 'row',
                        justifyContent: 'space-between',
                        paddingTop: 20,
                        paddingHorizontal: 10
                    }}>
                    <TouchableOpacity 
                        style={{alignSelf: 'center'}}
                        onPress={() => navigation.goBack()}>
                        <Icon 
                            name='chevron-left'
                            type='material'
                            color={'#2688EB'}
                            size={40}/>
                    </TouchableOpacity>
                    <View
                        style={{
                            flexDirection: 'column',
                        }}>
                        <Text
                            style={{
                                fontSize: 17,
                                fontWeight: '500',
                                color: 'black',
                                alignSelf: 'center'
                            }}>
                            {chat.name}
                        </Text>
                        <Text
                            style={{
                                alignSelf: 'center',
                                fontSize: 13,
                                color: '#787878',
                                fontWeight: '400'
                            }}>
                            {lastTimeOnlineString}
                        </Text>
                    </View>
                    <Image
                        style={{
                            width: 40,
                            height: 40,
                            borderRadius: 360,
                            alignSelf: 'center'
                        }}
                        source={{uri: `${env.api_url}/api/objects/${chat.iconUri}`}}/>    
                </View>
            </TouchableOpacity>
            {messages.length > 0 ?
            <>
                <FlatList
                    refreshControl={
                        <RefreshControl refreshing={refreshing} onRefresh={onRefresh}/>
                    }
                    data={[...messages].reverse()}
                    style={{paddingTop: 10}}
                    onViewableItemsChanged={onViewableItemsChanged.current}
                    viewabilityConfig={viewabilityConfig.current}
                    inverted
                    renderItem={({item, index}) => {
                        return (
                            <View style={{paddingHorizontal: 10, paddingTop: 2.5, paddingBottom: 2.5}}>
                                {
                                    index == messages.length-1 || dateHelper.getDateFromString([...messages].reverse()[index].creationTime) != dateHelper.getDateFromString([...messages].reverse()[index+1].creationTime) ?
                                    <>
                                        <View style={{paddingTop: 2.5}}>
                                            <View
                                                style={{
                                                    borderRadius: 20,
                                                    backgroundColor: '#DBE3FF82',
                                                    padding: 7,
                                                    alignSelf: 'center'
                                                }}>
                                                <Text
                                                    style={{
                                                        fontSize: 11,
                                                        fontWeight: '400',
                                                        color: '#6B89AC',
                                                        alignSelf: 'center'
                                                    }}>
                                                    {dateHelper.getDateFromString(item.creationTime)}
                                                </Text>    
                                            </View>
                                        </View>        
                                    </>
                                    :
                                    <>
                                    </>
                                }
                                <Message 
                                    message={item}
                                    userId={userStore.get().guid}
                                    confirmDate={confirmDate}
                                    enroll={enroll}
                                    changeStatus={changeStatus}
                                    openReviewModal={(id) => {
                                        setId(id);
                                        reviewsModalRef.current?.open();
                                    }}
                                    changeDate={(id) => {
                                        setId(id);
                                        enrollmentDateRef.current?.open()
                                    }}/>    
                            </View>
                        )
                    }}/>
            </>
            :
            <>
                <Text
                    style={{
                        fontWeight: '700',
                        fontSize: 24,
                        color: 'black',
                        alignSelf: 'center'
                    }}>
                    Нет сообщений
                </Text>
                <Text
                    style={{
                        color: '#818C99',
                        fontSize: 16,
                        paddingTop: 20,
                        fontWeight: '400',
                        alignSelf: 'center'
                    }}>
                    {`Можете запросить у компании любую\nинтересующую Вас информацию или\nсоздать заказ и дождаться ответов от\nкомпаний рядом с вами`}
                </Text>
                <View
                    style={{
                        paddingTop: 40,
                        paddingHorizontal: 80
                    }}>
                    <TouchableOpacity
                        style={styles.button}
                        onPress={async () => {
                            let categories = await categoryService.getCategories();

                            navigation.navigate('OrderRequestCreation', {category: categories[0]});
                        }}>
                        <Text
                            style={styles.buttonText}>
                            Создать заказ    
                        </Text>
                    </TouchableOpacity>    
                </View>
            </>}
            <View
                style={{
                    bottom: 0,
                    width,
                    position: messages.length > 0 ? 'relative' : 'absolute',
                    backgroundColor: 'white',
                }}>
                <View
                    style={{
                        flexDirection: 'row',
                        justifyContent: 'space-between',
                        paddingTop: 10,
                        paddingBottom: 20
                    }}>
                    <TouchableOpacity
                        style={{alignSelf: 'center'}}
                        onPress={sendImage}>
                        <Icon
                            type='material'
                            name='attach-file'
                            size={20}
                            color='#858E99'/>    
                    </TouchableOpacity>
                    <View
                        style={{paddingHorizontal: 5, flex: 1}}>
                        <View
                            style={{
                                flexDirection: 'row',
                                borderRadius: 15,
                                backgroundColor: 'white',
                                borderWidth: 1,
                                borderColor: '#D1D1D6',
                                paddingLeft: 10,
                                height: height/20,
                            }}>
                            <TextInput
                                style={{
                                    alignSelf: 'center',
                                    fontSize: 17,
                                    fontWeight: '400',
                                    color: 'black',
                                    flex: 1
                                }}
                                placeholder='Сообщение'
                                placeholderTextColor='#AEAEB2'
                                numberOfLines={1}
                                value={text}
                                onChangeText={(text) => setText(text)}/>    
                        </View>
                    </View>
                    <TouchableOpacity
                        style={{alignSelf: 'center'}}
                        disabled={text == ''}
                        onPress={text != '' && (async () => {
                            let message = await chatService.sendMessage(text, chat.guid);

                            setMessages(prev => {
                                prev.push(message);
                                return [...prev];
                            });
                            
                            setText('');
                        })}>
                        <Icon
                            type='material'
                            name='send'
                            size={20}
                            color='#858E99'/>    
                    </TouchableOpacity>
                </View>    
            </View>
        </View>
    );
}

export default ChatScreen;