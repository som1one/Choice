import React from 'react';
import {
    View,
    Text,
    ScrollView,
    Image,
    RefreshControl,
    TouchableOpacity,
    TextInput,
    Dimensions,
    Modal,
    DeviceEventEmitter
} from 'react-native';
import env from '../env';
import { useIsFocused } from '@react-navigation/native';
import userStore from '../services/userStore';
import styles from '../Styles';
import { Switch } from 'react-native';
import urlValidator from '../validators/urlValidator';
import { Icon } from 'react-native-elements';
import categoryStore from '../services/categoryStore';
import arrayHelper from '../helpers/arrayHelper';
import { Modalize } from 'react-native-modalize';
import CompanyCategorySelectionList from '../Components/CompanyCategorySelectionList';
import ImageBox from '../Components/ImageBox';
import { AuthContext } from '../App';
import companyService from '../services/companyService';
import blobService from '../services/blobService';
import CustomTextInput from '../Components/CustomTextInput';
import * as ImagePicker from 'react-native-image-picker';

const EditCompanyScreen = ({navigation, route}) => {
    const { signOut } = React.useContext(AuthContext);
    const [categoryString, setCategoryString] = React.useState();
    const { companyId, company } = route.params;
    const [trackedCategories, setTrackedCategories] = React.useState('');
    const modalRef = React.useRef(null);
    
    const [isChanged, setIsChanged] = React.useState(false);

    const convertCategoryToString = () => {
        let sortedArray = arrayHelper.where(trackedCategories, (c) => c.tracked);
        return arrayHelper.project(sortedArray, (c) => c.title).join(',');
    }

    const updateCategoryString = () => {
        let string = convertCategoryToString();

        return string == '' ? 'Виды деятельности' : string;
    }

    const isDisable = () => {
        const data = [
            title,
            email,
            phone,
            convertCategoryToString()
        ]

        const socialMedias = [
            instagramUrl,
            facebookUrl,
            vkUrl,
            tgUrl
        ]

        const isDataInvalid = data.some(s => s == '');
        const isAddressValid = address.includes(',') && address.split(',').every(s => s != '');
        const isSocialMediasInvalid = socialMedias.every(s => s == '');
        
        return isDataInvalid || !isAddressValid || isSocialMediasInvalid;
    }

    const getCategoryString = () => {
        const categories = categoryStore.getCategories();

        let trackedCategories = categories.map((c, i) => ({
            tracked: user.categoriesId.some(i => i == c.id),
            id: c.id,
            title: c.title,
            add: (i) => {}
        }));

        setTrackedCategories(trackedCategories);

        setCategoryString(arrayHelper.where(trackedCategories, (c) => c.tracked).map(c => c.title).join(','));
    }

    const getUrlIndex = (socialMediaName) => {
        let index = user.socialMedias.findIndex(s => s.includes(socialMediaName));
        
        if (index != -1) {
            return index;
        }

        return user.socialMedias.findIndex(s => s == '');
    }
    
    const getUrl = (name) => {
        switch(name) {
            case 'Instagram':
                return instagramUrl;
            case 'ВК':
                return vkUrl;
            case 'Facebook': 
                return facebookUrl;
            case 'Telegram':
                return tgUrl;
        }
    }

    const addImage = async () => {
        let response = await ImagePicker.launchImageLibrary();
        
        if (!response.didCancel) {
            let iconUri = await blobService.uploadImage(response.assets[0].uri);
            await companyService.changeIconUriAdmin(companyId, iconUri);
            setIconUri(response.assets[0].uri);
        }
    }

    const [currentIndex, setCurrentIndex] = React.useState(0);
    const [modalVisible, setModalVisible] = React.useState(false);
    const [currentUrl, setCurrentUrl] = React.useState('');

    const { width, height } = Dimensions.get('screen');

    const [user, setUser] = React.useState(company);
    const [refreshing, setRefreshing] = React.useState(false);
    const [iconUri, setIconUri] = React.useState(user == '' ? '' : `${env.api_url}/api/objects/${user.iconUri}`);

    const [title, setTitle] = React.useState(user == '' ? '' : user.title);
    const [email, setEmail] = React.useState(user == '' ? '' : user.email);
    const [phone, setPhone] = React.useState(user == '' ? '' : user.phoneNumber);
    const [address, setAddress] = React.useState(user == '' ? '' : `${user.address.city},${user.address.street}`);
    const [instagramUrl, setInstagramUrl] = React.useState(user == '' ? '' : user.socialMedias[getUrlIndex('instagram')]);
    const [facebookUrl, setFacebookUrl] = React.useState(user == '' ? '' : user.socialMedias[getUrlIndex('facebook')]);
    const [vkUrl, setVkUrl] = React.useState(user == '' ? '' : user.socialMedias[getUrlIndex('vk')]);
    const [tgUrl, setTgUrl] = React.useState(user == '' ? '' : user.socialMedias[getUrlIndex('t.me')]);
    const [fisrtImageUri, setFirstImageUri] = React.useState(user == '' ? '' : user.photoUris[0] != '' ? `${env.api_url}/api/objects/${user.photoUris[0]}` : '');
    const [secondImageUri, setSecondImageUri] = React.useState(user == '' ? '' : user.photoUris[1] != '' ? `${env.api_url}/api/objects/${user.photoUris[1]}` : '');
    const [thirdImageUri, setThirdImageUri] = React.useState(user == '' ? '' : user.photoUris[2] != '' ? `${env.api_url}/api/objects/${user.photoUris[2]}` : '');
    const [fourthImageUri, setFourthImageUri] = React.useState(user == '' ? '' : user.photoUris[3] != '' ? `${env.api_url}/api/objects/${user.photoUris[3]}` : '');
    const [fivthImageUri, setFivthImageUri] = React.useState(user == '' ? '' : user.photoUris[4] != '' ? `${env.api_url}/api/objects/${user.photoUris[4]}` : '');
    const [sixthImageUri, setSixthImageUri] = React.useState(user == '' ? '' : user.photoUris[5] != '' ? `${env.api_url}/api/objects/${user.photoUris[5]}` : '');
    const [prepayment, setPrepayment] = React.useState(user == '' ? false : user.prepaymentAvailable);

    const updateState = (user) => {
        setTitle(user.title);
        setIconUri(`${env.api_url}/api/objects/${user.iconUri}`);
        setEmail(user.email);
        setPhone(user.phoneNumber);
        setAddress(`${user.address.city},${user.address.street}`);
        setInstagramUrl(user.socialMedias[getUrlIndex('instagram')]);
        setFacebookUrl(user.socialMedias[getUrlIndex('facebook')]);
        setVkUrl(user.socialMedias[getUrlIndex('vk')]);
        setTgUrl(user.socialMedias[getUrlIndex('t.me')]);
        setFirstImageUri(user.photoUris[0] == '' ? user.photoUris[0] : `${env.api_url}/api/objects/${user.photoUris[0]}`);
        setSecondImageUri(user.photoUris[1] == '' ? user.photoUris[1] : `${env.api_url}/api/objects/${user.photoUris[1]}`);
        setThirdImageUri(user.photoUris[2] == '' ? user.photoUris[2] : `${env.api_url}/api/objects/${user.photoUris[2]}`);
        setFourthImageUri(user.photoUris[3] == '' ? user.photoUris[3] : `${env.api_url}/api/objects/${user.photoUris[3]}`);
        setFivthImageUri(user.photoUris[4] == '' ? user.photoUris[4] : `${env.api_url}/api/objects/${user.photoUris[4]}`);
        setSixthImageUri(user.photoUris[5] == '' ? user.photoUris[5] : `${env.api_url}/api/objects/${user.photoUris[5]}`);
        setPrepayment(user.prepayment);
    }

    const socialMedias = [
        {
            icon: require('../resources/instagram.png'),
            name: 'Instagram',
            url: () => getUrl('Instagram'),
            setUrl: (url) => setInstagramUrl(url),
            validate: (url) => urlValidator.validateInstagramUrl(url)
        },
        {
            icon: require('../resources/facebook.png'),
            name: 'Facebook',
            url: () => getUrl('Facebook'),
            setUrl: (url) => setFacebookUrl(url),
            validate: (url) => urlValidator.validateFacebookUrl(url)
        },
        {
            icon: require('../resources/vk.png'),
            name: 'ВК',
            url: () => getUrl('ВК'),
            setUrl: (url) => setVkUrl(url),
            validate: (url) => urlValidator.validateVkUrl(url)
        },
        {
            icon: require('../resources/telegram.png'),
            name: 'Telegram',
            url: () => getUrl('Telegram'),
            setUrl: (url) => setTgUrl(url),
            validate: (url) => urlValidator.validateTgUrl(url)
        }
    ]

    const isFocused = useIsFocused();

    const onRefresh = React.useCallback(async () => {
        setRefreshing(true);

        let company = await companyService.getAdmin(companyId);

        setUser(company);
        updateState(company);

        getCategoryString();

        setRefreshing(false);
    }, []);

    React.useEffect(() => {
        isFocused && onRefresh();
    }, [isFocused]);

    return (
        <ScrollView
            style={{
                flex: 1,
                backgroundColor: 'white',
            }}
            showsVerticalScrollIndicator={false}
            refreshControl={
                <RefreshControl refreshing={refreshing} onRefresh={onRefresh}/>
            }>
            <Modalize
                ref={modalRef}
                adjustToContentHeight={true}
                scrollViewProps={{nestedScrollEnabled: false, scrollEnabled: false}}
                childrenStyle={{height: '90%'}}>
                <View
                    style={{flex: 1}}>
                    <View
                        style={{
                            justifyContent: 'space-between',
                            flexDirection: 'row',
                            paddingHorizontal: 20,
                            paddingTop: 10
                        }}>
                        <Text></Text>
                        <Text
                            style={{
                                fontSize: 21,
                                fontWeight: '600',
                                color: 'black'
                            }}>
                            Виды деятельности
                        </Text>
                        <TouchableOpacity
                            style={{
                                borderRadius: 360,
                                backgroundColor: '#eff1f2',
                            }}
                            onPress={() => {
                                modalRef.current?.close();
                            }}>
                            <Icon
                                name='close'
                                type='material'
                                size={27}
                                color='#818C99'/>
                        </TouchableOpacity>
                    </View>
                    <CompanyCategorySelectionList 
                        categories={trackedCategories}/>
                    <View
                        style={{
                            paddingHorizontal: 10,
                            paddingTop: 20
                        }}>
                        <TouchableOpacity
                            style={styles.button}
                            onPress={() => {
                                DeviceEventEmitter.emit('addCategories');
                                modalRef.current?.close();
                                setCategoryString(updateCategoryString());  
                                setIsChanged(true);     
                            }}>
                            <Text
                                style={styles.buttonText}>
                                Выбрать
                            </Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </Modalize>
            <Modal
                visible={modalVisible}
                transparent={true}
                animationType='slide'>
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
                                    justifyContent: 'space-between',
                                    paddingTop: 20,
                                    paddingHorizontal: 20
                                }}>
                                <Text
                                    style={{
                                        fontSize: 24,
                                        fontWeight: '600',
                                        color: 'black'
                                    }}>
                                    {`Ссылка на ваш ${socialMedias[currentIndex].name}`}
                                </Text>
                                <TouchableOpacity
                                    onPress={() => {
                                        setCurrentUrl('');
                                        setModalVisible(false);
                                    }}
                                    style={{
                                        borderRadius: 360,
                                        backgroundColor: '#eff1f2',
                                        alignSelf: 'flex-start',
                                        padding: 2
                                    }}>
                                    <Icon 
                                        name='close'
                                        type='material'
                                        size={27}
                                        color='#818C99'/>
                                </TouchableOpacity>
                            </View>
                            <View style={{paddingHorizontal: 20, paddingTop: 10}}>
                                <View
                                    style={styles.textInput}>
                                    <TextInput 
                                        style={styles.textInputFont}
                                        value={currentUrl}
                                        onChangeText={setCurrentUrl}/>
                                </View>
                            </View>
                            <View
                                style={{
                                    justifyContent: 'center',
                                }}>
                                <View
                                    style={{
                                        paddingTop: 10,
                                        paddingBottom: 10,
                                        paddingHorizontal: 20
                                    }}>
                                    <TouchableOpacity 
                                        style={[styles.button, {borderRadius: 10}]}
                                        onPress={() => {
                                            if (socialMedias[currentIndex].validate(currentUrl)) {
                                                socialMedias[currentIndex].setUrl(currentUrl);
                                                setIsChanged(true);
                                            }

                                            setModalVisible(false);
                                            setCurrentUrl('');
                                        }}>
                                        <Text style={styles.buttonText}>Сохранить</Text>
                                    </TouchableOpacity>
                                </View>
                            </View>
                        </View>
                    </View>
                </View>
            </Modal>
            <View
                style={{paddingHorizontal: 20}}>
                <View
                    style={{
                        flexDirection: 'row',
                        justifyContent: 'space-between',
                        paddingTop: 20,
                    }}>
                    <TouchableOpacity
                        style={{
                            alignSelf: 'center'
                        }}
                        onPress={() => navigation.goBack()}>
                        <Icon
                            type='material'
                            name='chevron-left'
                            color='#2688EB'
                            size={30}/>
                    </TouchableOpacity>
                    <Text></Text>
                </View>
                <Text
                    style={{
                        top: 20,
                        color: 'black',
                        fontWeight: '600',
                        fontSize: 21,
                        position: 'absolute',
                        alignSelf: 'center'
                    }}>
                    Компания
                </Text>
                <View
                    style={{
                        paddingTop: 40
                    }}>
                    <Image
                        style={{
                            height: 70,
                            width: 70,
                            borderRadius: 360,
                            alignSelf: 'center'
                        }}
                        source={{uri: iconUri}}/>
                </View>
                <View
                    style={{
                        paddingTop: 20,
                        alignSelf: 'center' 
                    }}>
                    <TouchableOpacity
                        style={{
                            alignSelf: 'center'
                        }}
                        onPress={addImage}>
                        <Text
                            style={{
                                color: '#2D81E0',
                                fontWeight: '500',
                                fontSize: 15
                            }}>
                            Изменить логотип
                        </Text>
                    </TouchableOpacity>
                </View>
                <View 
                    style={{paddingTop: 20}}> 
                    <View
                        style={{
                            height: .25,
                            backgroundColor: '#D7D8D9',
                        }}/>        
                </View>
                <Text
                    style={{
                        fontWeight: '700',
                        fontSize: 17,
                        paddingTop: 10,
                        color: 'black'
                    }}>
                    Контактные данные    
                </Text>
                <Text
                    style={{
                        color: '#181818',
                        fontSize: 16,
                        fontWeight: '400',
                        paddingTop: 10
                    }}>
                    {'Укажите информацию, которая будет\nотображаться в карточке вашей компании,\nее увидят тысячи наших пользователей'}
                </Text>
                <Text
                    style={{
                        color: '#6D7885',
                        fontWeight: '400',
                        fontSize: 14,
                        paddingTop: 20,
                        paddingBottom: 5
                    }}>
                    Название
                </Text>
                <CustomTextInput
                    value={title}
                    changed={(text) => {
                        setTitle(text);
                        setIsChanged(true);
                    }}/>
                <Text
                    style={{
                        color: '#6D7885',
                        fontWeight: '400',
                        fontSize: 14,
                        paddingTop: 20,
                        paddingBottom: 5
                    }}>
                    E-mail
                </Text>
                <CustomTextInput
                    value={email}
                    changed={(text) => {
                        setEmail(text);
                        setIsChanged(true);
                    }}/>
                <Text
                    style={{
                        color: '#6D7885',
                        fontWeight: '400',
                        fontSize: 14,
                        paddingTop: 20,
                        paddingBottom: 5
                    }}>
                    Телефон
                </Text>
                <CustomTextInput
                    style={styles.textInputFont}
                    value={phone}
                    type='phone-pad'
                    max={10}
                    onChangeText={(text) => {
                        setPhone(text);
                        setIsChanged(true);
                    }}/>
                <Text
                    style={{
                        color: '#6D7885',
                        fontWeight: '400',
                        fontSize: 14,
                        paddingTop: 20,
                        paddingBottom: 5
                    }}>
                    Адрес
                </Text>
                <CustomTextInput
                    value={address}
                    changed={(text) => {
                        setAddress(text);
                        setIsChanged(true);
                    }}
                    big/>
                <View 
                    style={{paddingTop: 10}}> 
                    <View
                        style={{
                            height: .5,
                            backgroundColor: '#D7D8D9',
                        }}/>        
                </View>
                <Text
                    style={{
                        paddingTop: 10,
                        color: 'black',
                        fontWeight: '700',
                        fontSize: 21
                    }}>
                    Социальные сети    
                </Text>
                <View style={{paddingTop: 20}}>
                    {socialMedias.map((item, i) => (
                        <View
                            style={{
                                flexDirection: 'row', 
                                paddingBottom: 5,   
                            }}
                            key={i}>
                            <Image 
                                source={item.icon}
                                style={{
                                    width: 20,
                                    height: 20,
                                    resizeMode: 'contain',
                                    alignSelf: 'center'
                                }}/>
                            <View
                                style={{
                                    justifyContent: 'space-between',
                                    flexDirection: 'column',
                                    alignSelf: 'center',
                                    paddingLeft: 5
                                }}>
                                <Text
                                    style={{
                                        color: 'black',
                                        fontWeight: '400',
                                        fontSize: 15,
                                        alignSelf: 'center'
                                    }}>
                                    {item.name}
                                </Text>
                            </View>
                            <View
                                style={{
                                    flex: 1,
                                    flexDirection: 'row',
                                    justifyContent: 'flex-end'
                                }}>
                                <Switch
                                    trackColor={{true: '#2688EB', false: '#001C3D14'}} 
                                    thumbColor={'white'}
                                    value={item.url() != ""}
                                    onValueChange={(value) => {
                                        if (value) {
                                            setCurrentIndex(i);
                                            setModalVisible(true);
                                        }   
                                        else {
                                            item.setUrl('');
                                            setIsChanged(true);
                                        }
                                    }}/>
                            </View>    
                        </View>
                    ))}
                </View>
                <View
                    style={{
                        paddingTop: 10
                    }}>
                    <Text
                        style={{
                            fontSize: 21,
                            fontWeight: '700',
                            color: 'black'
                        }}>
                        О работе
                    </Text>
                    <Text
                        style={{
                            fontWeight: '400',
                            fontSize: 14,
                            color: '#6D7885',
                            paddingTop: 10,
                            paddingBottom: 5
                        }}>
                        Виды деятельности
                    </Text>
                    <View
                        style={[styles.textInput(false, false), {
                            flexDirection: 'row'
                        }]}>
                        <Text
                            style={[styles.textInputFont, {flex: 1, alignSelf: 'center'}]}>
                            {categoryString}
                        </Text>
                        <TouchableOpacity
                            style={{alignSelf: 'center'}}
                            onPress={() => modalRef.current?.open()}>
                            <Icon
                                name='expand-more'
                                type='material'
                                size={27}
                                color='gray'/>
                        </TouchableOpacity>
                    </View>
                    <View
                        style={{
                            justifyContent: 'space-between',
                            flexDirection: 'row',
                            paddingTop: 10
                        }}>
                        <ImageBox
                            uri={fisrtImageUri}
                            onUriChanged={(uri) => {
                                setFirstImageUri(uri);
                                setIsChanged(true);
                            }}/>

                        <ImageBox
                            uri={secondImageUri}
                            onUriChanged={(uri) => {
                                setSecondImageUri(uri);
                                setIsChanged(true);
                            }}/>

                        <ImageBox
                            uri={thirdImageUri}
                            onUriChanged={(uri) => {
                                setThirdImageUri(uri);
                                setIsChanged(true);
                            }}/>          
                    </View>
                    <View
                        style={{
                            paddingTop: 10,
                            justifyContent: 'space-between',
                            flexDirection: 'row'
                        }}>
                        <ImageBox
                            uri={fourthImageUri}
                            onUriChanged={(uri) => {
                                setFourthImageUri(uri);
                                setIsChanged(true);
                            }}/>

                        <ImageBox
                            uri={fivthImageUri}
                            onUriChanged={(uri) => {
                                setFivthImageUri(uri);
                                setIsChanged(true);
                            }}/>

                        <ImageBox
                            uri={sixthImageUri}
                            onUriChanged={(uri) => {
                                setSixthImageUri(uri);
                                setIsChanged(true);
                            }}/>          
                    </View>
                    <Text
                        style={{
                            color: '#6D7885',
                            fontWeight: '400',
                            fontSize: 14,
                            paddingTop: 20
                        }}
                        >
                        Опции    
                    </Text>
                    <View
                        style={{
                            flexDirection: 'row',
                            paddingTop: 10
                        }}>
                        <TouchableOpacity
                            style={{
                                alignSelf: 'center'
                            }}
                            disabled={prepayment}
                            onPress={() => {
                                setPrepayment(true);
                                setIsChanged(true);
                            }}>
                            <Icon 
                                type='material'
                                name={prepayment ? 'radio-button-checked' : 'radio-button-unchecked'}
                                color={!prepayment ? '#B8C1CC' : '#2688EB'}/>
                        </TouchableOpacity>
                        <Text
                            style={{
                                paddingLeft: 10,
                                color: 'black',
                                fontSize: 15,
                                fontWeight: '400',
                                alignSelf: 'center'
                            }}>
                            Работа с предоплатой    
                        </Text>
                    </View>
                    <View
                        style={{
                            flexDirection: 'row',
                            paddingTop: 20
                        }}>
                        <TouchableOpacity
                            style={{
                                alignSelf: 'center'
                            }}
                            disabled={!prepayment}
                            onPress={() => {
                                setPrepayment(false);
                                setIsChanged(true);
                            }}>
                            <Icon 
                                type='material'
                                name={!prepayment ? 'radio-button-checked' : 'radio-button-unchecked'}
                                color={prepayment ? '#B8C1CC' : '#2688EB'}/>
                        </TouchableOpacity>
                        <Text
                            style={{
                                paddingLeft: 10,
                                color: 'black',
                                fontSize: 15,
                                fontWeight: '400',
                                alignSelf: 'center'
                            }}>
                            Работа без предоплаты  
                        </Text>
                    </View>    
                </View>
                <View
                    style={{
                        paddingTop: 20
                    }}>
                    <TouchableOpacity 
                        style={{
                            backgroundColor: '#F2F3F5', 
                            height: height/18, 
                            borderRadius: 10, 
                            justifyContent: 'center'
                        }}
                        onPress={async () => {
                            console.log(company);
                            await companyService.deleteCompany(company.guid);
                            navigation.goBack();
                        }}>
                        <View 
                            style={{
                                flexDirection: 'row', 
                                justifyContent: 'center'
                            }}>
                            <Text 
                                style={{
                                    color: '#EB2626', 
                                    fontSize: 17, 
                                    fontWeight: '500', 
                                    alignSelf: 'center'
                                }}>
                                Удалить компанию
                            </Text>
                        </View>
                    </TouchableOpacity>
                </View>
                <View
                    style={{
                        paddingTop: 20,
                        justifyContent: 'center'
                    }}>
                    {
                        isChanged ?
                        <>
                            <View
                                style={{paddingTop: 10}}>
                                <TouchableOpacity
                                    style={[styles.button, {
                                        backgroundColor: isDisable() ? '#ABCDf3' : '#2D81E0'
                                    }]}
                                    disabled={isDisable()}
                                    onPress={!isDisable() && (async () => {
                                        const state = {
                                            guid: companyId,
                                            title,
                                            email,
                                            phoneNumber: phone,
                                            street: address.split(',')[1],
                                            city: address.split(',')[0],
                                            siteUrl: user.siteUrl,
                                            photoUris: [
                                                fisrtImageUri, 
                                                secondImageUri, 
                                                thirdImageUri, 
                                                fourthImageUri, 
                                                fivthImageUri, 
                                                sixthImageUri
                                            ],
                                            socialMedias: [
                                                instagramUrl,
                                                facebookUrl,
                                                vkUrl,
                                                tgUrl
                                            ],
                                            categoriesId: trackedCategories.filter(c => c.tracked).map(c => c.id)
                                        };

                                        for (let i = 0; i < 6; i++) {
                                            if (state.photoUris[i][0] == 'f') {
                                                state.photoUris[i] = await blobService.uploadImage(state.photoUris[i]);
                                            }
                                            else {
                                                let dirs = state.photoUris[i].split('/');
                                                state.photoUris[i] = dirs[dirs.length-1];
                                                console.log(dirs[dirs.length-1]);
                                            }
                                        }

                                        await companyService.changeDataAdmin(state);

                                        setIsChanged(false);
                                        navigation.goBack();
                                    })}>
                                    <Text
                                        style={styles.buttonText}>
                                        Сохранить изменения
                                    </Text>    
                                </TouchableOpacity> 
                            </View>
                        </>
                        :
                        <>
                        </>
                    }
                </View>
            </View>
        </ScrollView>
    )
}

export default EditCompanyScreen;