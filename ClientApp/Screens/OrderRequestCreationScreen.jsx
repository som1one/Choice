import React, { useRef } from "react";
import {
    View,
    TouchableOpacity,
    Text,
    TextInput,
    Dimensions,
    ScrollView,
    Modal,
    DeviceEventEmitter
} from 'react-native';
import { Icon } from "react-native-elements";
import { Slider } from "react-native-awesome-slider";
import styles from "../Styles";
import ImageBox from "../Components/ImageBox";
import { useSharedValue } from "react-native-reanimated";
import categoryStore from "../services/categoryStore";
import { Modalize } from "react-native-modalize";
import { FlatList } from "react-native-gesture-handler";
import Category from "../Components/Category";
import clientService from "../services/clientService";
import blobService from "../services/blobService";
import CustomTextInput from "../Components/CustomTextInput";
import Voice from '@react-native-voice/voice'

const OrderRequestCreationScreen = ({ navigation, route }) => {
    const modalRef = useRef(null);

    const categories = categoryStore.getCategories();

    const { category } = route.params;

    const [selectedCategory, setSelectedCategory] = React.useState({title: category.title, track: true, id: category.id});
    const { width, height } = Dimensions.get('screen');
    const [fisrtImageUri, setFirstImageUri] = React.useState('');
    const [secondImageUri, setSecondImageUri] = React.useState('');
    const [thirdImageUri, setThirdImageUri] = React.useState('');

    const [disabled, setDisabled] = React.useState(true);

    const [orderRequest, setOrderRequest] = React.useState({
        id: 0,
        status: 0,
        description: '',
        categoryId: 0,
        searchRadius: 0,
        toKnowPrice: false,
        toKnowDeadline: false,
        toKnowEnrollmentDate: false,
        creationDate: '',
        photoUris: []
    });

    const updateDisabled = (state) => {
        setDisabled((state.description == '' || 
            (!state.toKnowPrice && !state.toKnowDeadline && !state.toKnowEnrollmentDate)));
    }

    const progress = useSharedValue(10);
    const min = useSharedValue(5);
    const max = useSharedValue(25);
    const [modalVisible, setModalVisibility] = React.useState(false);

    const [description, setDescription] = React.useState('');
    const [toKnowPrice, setToKnowPrice] = React.useState(false);
    const [radius, setRadius] = React.useState(10);
    const [toKnowDeadline, setToKnowDeadline] = React.useState(false);
    const [toKnowEnrollmentDate, setToKnowEnrollmentDate] = React.useState(false);
    const [isRecording, setIsRecording] = React.useState(false);

    const selectCategory = (newCategory) => {
        if (newCategory.track) {
            setSelectedCategory(newCategory);
            updateDisabled({
                description,
                toKnowPrice,
                toKnowDeadline,
                toKnowEnrollmentDate,
                fisrtImageUri,
                secondImageUri,
                thirdImageUri
            });
        }
    }

    React.useEffect(() => {
        Voice.onSpeechEnd = onSpeechEnd;
        Voice.onSpeechResults = onSpeechResults;

        return () => {
            Voice.destroy().then(Voice.removeAllListeners);
        };
    }, []);

    const onSpeechEnd = (e) => {
        setIsRecording(false);
    } 

    const onSpeechResults = (e) => {
        console.log(e);
        setDescription(e.value[0]);
    }

    return (
        <ScrollView 
            style={{
                flex:1, 
                backgroundColor: 'white'
            }}
            showsVerticalScrollIndicator={false}>
            <Modal
                visible={modalVisible}
                transparent={true}>
                <View
                    style={{
                        height,
                        width,
                        backgroundColor: 'rgba(0,0,0,0.5)',
                    }}>
                    <View
                        style={{
                            backgroundColor: 'white',
                            width: '90%',
                            borderRadius: 20,
                            alignSelf: 'center',
                            position: 'absolute',
                            bottom: height/9
                        }}>
                        <View 
                            style={{
                                flex: 1,
                                flexDirection: 'column'
                            }}>
                            <View 
                                style={{
                                    flexDirection: 'row',
                                    justifyContent: 'flex-end',
                                    paddingTop: 20,
                                    paddingHorizontal: 10
                                }}>
                                <TouchableOpacity
                                    onPress={() => {
                                        DeviceEventEmitter.emit('orderRequestCreated', {
                                            selectedCategory: {
                                                id: selectedCategory.id,
                                                title: selectedCategory.title
                                            }, 
                                            createdOrderRequest: orderRequest
                                        });
                                        navigation.goBack();
                                    }}
                                    style={{
                                        borderRadius: 360,
                                        backgroundColor: '#eff1f2',
                                        alignSelf: 'flex-start'
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
                                    justifyContent: 'center',
                                }}>
                                <Icon 
                                    name='thumb-up'
                                    type='material'
                                    color='#2D81E0'
                                    size={40}/>
                                <Text
                                    style={{
                                        color: 'black',
                                        fontWeight: '500',
                                        fontSize: 20,
                                        alignSelf: 'center',
                                        paddingTop: 10
                                        
                                    }}>
                                    Заказ создан
                                </Text>
                                <Text 
                                    style={{
                                        paddingTop: 10,
                                        color: '#6D7885',
                                        fontSize: 14,
                                        fontWeight: '400',
                                        alignSelf: 'center'
                                    }}>
                                    Тысячи компаний увидят ваш зазаз и ответят    
                                </Text>
                                <Text 
                                    style={{
                                        color: '#6D7885',
                                        fontSize: 14,
                                        fontWeight: '400',
                                        alignSelf: 'center'
                                    }}>
                                    вам в самое ближайшее время    
                                </Text>
                                <View
                                    style={{
                                        paddingTop: 10,
                                        paddingBottom: 10,
                                        paddingHorizontal: 10
                                    }}>
                                    <TouchableOpacity 
                                        style={[styles.button, {borderRadius: 10}]}
                                        onPress={() => {
                                            DeviceEventEmitter.emit('orderRequestCreated', {
                                                selectedCategory: {
                                                    id: selectedCategory.id,
                                                    title: selectedCategory.title
                                                }, 
                                                createdOrderRequest: orderRequest
                                            });
                                            navigation.goBack();
                                        }}>
                                        <Text style={styles.buttonText}>Ок</Text>
                                    </TouchableOpacity>
                                </View>
                            </View>
                        </View>
                    </View>
                </View>
            </Modal>
            <Modalize 
                ref={modalRef}
                adjustToContentHeight={true}
                childrenStyle={{height: '100%'}}>

                <View
                    style={{
                        paddingHorizontal: 15,
                        paddingTop: 10
                    }}>        
                    <View
                        style={{
                            flexDirection: 'row',
                            justifyContent: 'space-between',
                            paddingTop: 10,
                        }}>
                        <Text></Text>
                        <Text 
                            style={{
                                color: 'black',
                                fontSize: 21,
                                fontWeight: '600',
                            }}>
                            Категория услуг
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
                    <FlatList
                        data={categories}
                        scrollEnabled={false}
                        style={{ paddingTop: 10 }} 
                        renderItem={({item}) => {
                        return (
                            <Category 
                                category={{
                                    title: item.title,
                                    track: selectedCategory.id == item.id,
                                    id: item.id
                                }}
                                selectCategory={(category) => selectCategory(category)}/>
                        );
                    }}/>
                </View>
            </Modalize>
            <View style={{flexDirection: 'row', justifyContent: 'space-between', paddingTop: 20}}>
                <TouchableOpacity 
                    style={{alignSelf: 'center'}}
                    onPress={() => navigation.goBack()}>
                    <Icon name='chevron-left'
                          type='material'
                          color={'#2688EB'}
                          size={40}/>
                </TouchableOpacity>
                <Text style={{alignSelf: 'center', color: 'black', fontWeight: '600', fontSize: 21}}>Создание заказа</Text>
                <Text></Text>
            </View>
            <View style={{paddingHorizontal: 20}}>
                <View style={{paddingTop: 20}}>
                    <Text style={{fontSize: 14, fontWeight: '400', color: '#6D7885', paddingBottom: 10}}>Категория услуг</Text>
                    <View style={[styles.textInput(false, false), {flexDirection: 'row'}]}>
                        <Text style={[styles.textInputFont, {alignSelf: 'center', flex: 3}]}>{selectedCategory.title}</Text>
                        <View style={{flex: 1, flexDirection: 'row', justifyContent: 'flex-end'}}>
                            <TouchableOpacity 
                                style={{alignSelf: 'center'}}
                                onPress={() => modalRef.current?.open()}>
                                <Icon type='material'
                                    color='gray'
                                    name='expand-more'/>
                            </TouchableOpacity>
                        </View>
                    </View>
                </View>
                <View style={{paddingTop: 30}}>
                    <Text style={{fontSize: 14, fontWeight: '400', color: '#6D7885', paddingBottom: 10}}>Описание задачи</Text>
                        <CustomTextInput 
                            value={description}
                            changed={(value) => { 
                                setDescription(value);
                                updateDisabled({
                                    description: value,
                                    toKnowPrice,
                                    toKnowDeadline,
                                    toKnowEnrollmentDate,
                                    fisrtImageUri,
                                    secondImageUri,
                                    thirdImageUri
                                });
                            }}
                            multiline
                            big
                            placeholder="Введите подробности задачи, в чем вам нужна помощь и какой вы ожидаете результат"/>
                </View>
                <View 
                    style={{paddingTop: 10}}>
                    <TouchableOpacity 
                        style={{
                            backgroundColor: '#F2F3F5', 
                            height: height/18, 
                            borderRadius: 10, 
                            justifyContent: 'center'
                        }}
                        onPress={() => {
                            setIsRecording(prev => {
                                if (prev) {
                                    Voice.stop();
                                }
                                else {
                                    Voice.start('ru-RU');
                                }

                                return !prev;
                            });
                        }}>
                        <View 
                            style={{
                                flexDirection: 'row', 
                                justifyContent: 'center'
                            }}>
                            {isRecording ?
                            <>
                                <Icon
                                    type="material"
                                    name="stop-circle"
                                    color="#3F8AE0"/>
                            </>
                            :
                            <>
                                <Icon 
                                    name='mic'
                                    type='material'
                                    color='#3F8AE0'/>
                                <Text 
                                    style={{
                                        color: '#2688EB', 
                                        fontSize: 17, 
                                        fontWeight: '500', 
                                        alignSelf: 'center'
                                    }}>
                                    Записать голосом
                                </Text>
                            </>}
                        </View>
                    </TouchableOpacity>
                </View>
                <View style={{paddingTop:30}}>
                    <Text style={{fontSize: 14, fontWeight: '400', color: '#6D7885', paddingBottom: 10}}>Что узнать у продавца</Text>
                    <View style={{flexDirection: 'row'}}>
                        <TouchableOpacity 
                            style={{width: 20, height: 20, borderColor: '#B8C1CC', borderWidth: toKnowPrice ? 0 : 2, backgroundColor: toKnowPrice ? '#2688EB' : 'white', borderRadius: 4, justifyContent: 'center'}}
                            onPress={() => { 
                                setToKnowPrice(!toKnowPrice);
                                updateDisabled({
                                    description,
                                    toKnowPrice: !toKnowPrice,
                                    toKnowDeadline,
                                    toKnowEnrollmentDate,
                                    fisrtImageUri,
                                    secondImageUri,
                                    thirdImageUri
                                });
                            }}>
                            <Icon name='done'
                                  type='material'
                                  color={'white'}
                                  size={15}/>
                        </TouchableOpacity>
                        <Text style={{fontSize: 15, fontWeight: '400', color: 'black', paddingLeft: 10}}>Узнать стоимость</Text>
                    </View>
                    <View style={{flexDirection: 'row', paddingTop: 10}}>
                        <TouchableOpacity 
                            style={{width: 20, height: 20, borderColor: '#B8C1CC', borderWidth: toKnowDeadline ? 0 : 2, backgroundColor: toKnowDeadline ? '#2688EB' : 'white', borderRadius: 4, justifyContent: 'center'}}
                            onPress={() => { 
                                setToKnowDeadline(!toKnowDeadline);
                                updateDisabled({
                                    description,
                                    toKnowPrice,
                                    toKnowDeadline: !toKnowDeadline,
                                    toKnowEnrollmentDate,
                                    fisrtImageUri,
                                    secondImageUri,
                                    thirdImageUri
                                });
                            }}>
                            <Icon name='done'
                                  type='material'
                                  color={'white'}
                                  size={15}/>
                        </TouchableOpacity>
                        <Text style={{fontSize: 15, fontWeight: '400', color: 'black', paddingLeft: 10}}>Узнать время выполнения работ</Text>
                    </View>
                    <View style={{flexDirection: 'row', paddingTop: 10}}>
                        <TouchableOpacity 
                            style={{width: 20, height: 20, borderColor: '#B8C1CC', borderWidth: toKnowEnrollmentDate ? 0 : 2, backgroundColor: toKnowEnrollmentDate ? '#2688EB' : 'white', borderRadius: 4, justifyContent: 'center'}}
                            onPress={() => { 
                                setToKnowEnrollmentDate(!toKnowEnrollmentDate);
                                updateDisabled({
                                    description,
                                    toKnowPrice,
                                    toKnowDeadline,
                                    toKnowEnrollmentDate: !toKnowEnrollmentDate,
                                    fisrtImageUri,
                                    secondImageUri,
                                    thirdImageUri
                                });
                            }}>
                            <Icon name='done'
                                  type='material'
                                  color={'white'}
                                  size={15}/>
                        </TouchableOpacity>
                        <Text style={{fontSize: 15, fontWeight: '400', color: 'black', paddingLeft: 10}}>Узнать время записи</Text>
                    </View>
                </View>
                <View style={{paddingTop: 30}}>
                    <Text style={{fontSize: 14, fontWeight: '400', color: '#6D7885', paddingBottom: 10}}>Приложите файлы к заказу</Text>
                    <View style={{flexDirection: 'row', justifyContent: 'space-between'}}>
                        <ImageBox 
                            onUriChanged={(state) => { 
                                setFirstImageUri(state);
                            }}
                            uri={''}/>
                        <ImageBox 
                            onUriChanged={(state) => { 
                                setSecondImageUri(state);
                            }}
                            uri={''}/>
                        <ImageBox 
                            onUriChanged={(state) => { 
                                setThirdImageUri(state);
                            }}
                            uri={''}/>
                    </View>
                </View>
                <View 
                    style={{
                        paddingTop: 30,
                    }}>
                    <View 
                        style={{
                            flexDirection: 'row',
                            justifyContent: 'space-between'
                        }}>
                        <Text 
                            style={{
                                fontSize: 14, 
                                fontWeight: '400', 
                                color: '#6D7885', 
                                paddingBottom: 20
                            }}>
                            Радиус поиска
                        </Text>
                        <Text
                            style={{
                                fontSize: 14,
                                color: 'black',
                                fontWeight: '600'
                            }}>
                            {`${radius} км`}
                        </Text>
                    </View>
                    <Slider minimumValue={min}
                            progress={progress}
                            maximumValue={max}
                            onValueChange={(value) => setRadius(Math.floor(value))}
                            theme={{
                                disableMinTrackTintColor: '#007AFF',
                                maximumTrackTintColor: '#78788033',
                                minimumTrackTintColor: '#007AFF',
                            }}
                            renderBubble={() => {}}
                            renderThumb={() => (
                                <View 
                                    style={{
                                        borderRadius: 360,
                                        backgroundColor: 'white',
                                        width: 25,
                                        height: 25,
                                        borderWidth: 1,
                                        borderColor: '#78788033'
                                    }}>

                                </View>
                            )}/>
                    <View
                        style={{
                            flexDirection: 'row',
                            justifyContent: 'space-between',
                            paddingTop: 20
                        }}>
                        <Text
                            style={{
                                fontSize: 14, 
                                fontWeight: '400', 
                                color: '#6D7885', 
                            }}>
                            от 5 км
                        </Text>
                        <Text
                            style={{
                                fontSize: 14, 
                                fontWeight: '400', 
                                color: '#6D7885', 
                            }}>
                            до 25 км
                        </Text>
                    </View>
                </View>
                <View 
                    style={{
                        paddingTop: 30,
                        paddingBottom: 10
                    }}>
                    <TouchableOpacity 
                        style={[styles.button, {backgroundColor: disabled ? '#ABCDf3' : '#2D81E0'}]}
                        disabled={disabled}
                        onPress={!disabled && (async () => {
                            setModalVisibility(true);
                            let state = {
                                description,
                                categoryId: selectedCategory.id,
                                photoUris: [fisrtImageUri, secondImageUri, thirdImageUri],
                                searchRadius: radius*1000,
                                toKnowPrice,
                                toKnowDeadline,
                                toKnowEnrollmentDate
                            }

                            let i = 0;
                            for (; i < 3; i++) {
                                state.photoUris[i] = await blobService.uploadImage(state.photoUris[i]);
                            }

                            let orderRequest = await clientService.sendOrderRequest(state);
                            setOrderRequest(orderRequest);
                        })}>
                        <Text style={styles.buttonText}>Создать заказ</Text>
                    </TouchableOpacity>
                </View>
            </View>
        </ScrollView>
    )
}

export default OrderRequestCreationScreen;