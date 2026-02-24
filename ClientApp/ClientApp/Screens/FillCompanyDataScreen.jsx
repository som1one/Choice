import React from "react";
import {
    View,
    Text,
    Dimensions,
    FlatList,
    Modal,
    TouchableOpacity
} from 'react-native';
import ContactDetailsScreen from "./ContactDetailsScreen";
import SocialMediasScreen from "./SocialMediasScreen";
import AboutScreen from "./AboutScreen";
import styles from "../Styles";
import { Icon } from "react-native-elements";
import companyService from "../services/companyService";
import authService from "../services/authService";
import { AuthContext } from "../App";
import blobService from "../services/blobService";
import userStore from "../services/userStore";

const FillCompanyDataScreen = ({navigation, route}) => {
    const { email, password } = route.params;

    const { width, height } = Dimensions.get('screen');

    const [siteUrl, setSiteUrl] = React.useState('');
    const [socialMedias, setSocialMedias] = React.useState([]);
    const [categoriesId, setCategoriesId] = React.useState([]);
    const [prepaymentAvailable, setPrepayment] = React.useState(false);
    const [photoUris, setPhotoUris] = React.useState([]);
    const [description, setDescription] = React.useState('');

    const [index, setIndex] = React.useState(1); 
    const [modalVisible, setModalVisible] = React.useState(false);

    const ref = React.useRef();

    const { signIn } = React.useContext(AuthContext);

    const data = [
        {
            screen: ContactDetailsScreen,
            handleState: (text) => {
                setSiteUrl(text);
                onItemPress(1);
                setIndex(2);
            }
        },
        {
            screen: SocialMediasScreen,
            handleState: (socialMedias) => {
                setSocialMedias(socialMedias);
                onItemPress(2);
                setIndex(3);
            }
        },
        {
            screen: AboutScreen,
            handleState: (state) => {
                setCategoriesId(state.categories);
                setPrepayment(state.prepayment);
                setPhotoUris(state.photoUris);
                setDescription(state.description);

                setModalVisible(true);
            }
        }
    ]

    const onItemPress = React.useCallback(itemIndex => {
        ref?.current?.scrollToOffset({
            offset: itemIndex * width
        });
    });

    const fillCompanyData = async () => {
        for (let i = 0; i < 6; i++) {
            photoUris[i] = await blobService.uploadImage(photoUris[i]);
        }

        let status = await companyService.fillCompanyData({
            siteUrl,
            socialMedias,
            photoUris,
            categoriesId,
            prepaymentAvailable,
            description 
        });

        if (status == 200) {
            await new Promise(r => setTimeout(r, 2000));

            setModalVisible(false);
            
            await authService.loginByEmail(email, password);
            await userStore.retrieveData(2);

            await signIn(2);
        }
    }

    return (
        <View
            style={{
                flex: 1,
                backgroundColor: 'white'
            }}>
            <Modal
                visible={modalVisible}
                transparent={true}
                animationType="slide">
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
                                    onPress={async () => {
                                        await fillCompanyData();
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
                                    Отлично
                                </Text>
                                <Text 
                                    style={{
                                        paddingTop: 10,
                                        color: '#6D7885',
                                        fontSize: 14,
                                        fontWeight: '400',
                                        alignSelf: 'center'
                                    }}>
                                    Теперь тысячи пользователей увидят вашу
                                </Text>
                                <Text 
                                    style={{
                                        color: '#6D7885',
                                        fontSize: 14,
                                        fontWeight: '400',
                                        alignSelf: 'center'
                                    }}>
                                    компанию, вы сможете отвечать на их запросы   
                                </Text>
                                <View
                                    style={{
                                        paddingTop: 10,
                                        paddingBottom: 10,
                                        paddingHorizontal: 10
                                    }}>
                                    <TouchableOpacity 
                                        style={[styles.button, {borderRadius: 10}]}
                                        onPress={async () => {
                                            await fillCompanyData();
                                        }}>
                                        <Text style={styles.buttonText}>
                                            Понятно
                                        </Text>
                                    </TouchableOpacity>
                                </View>
                            </View>
                        </View>
                    </View>
                </View>
            </Modal>
            <View>
                <Text
                    style={{
                        color: 'black',
                        fontSize: 21,
                        fontWeight: '600',
                        paddingTop: 20,
                        alignSelf: 'center'
                    }}>
                    Карточкая компании
                </Text>
                <View style={{paddingHorizontal: 20}}>
                    <View
                        style={{
                            paddingTop: 30,
                            justifyContent: 'space-between',
                            flexDirection: 'row'
                        }}>
                        <View
                            style={{
                                height: 4.5,
                                width: width/3.5,
                                borderRadius: 10,
                                backgroundColor: 1 <= index ? '#2688EB' : '#DFDFDF'
                            }}/> 
                        <View
                            style={{
                                height: 4.5,
                                width: width/3.5,
                                borderRadius: 10,
                                backgroundColor: 2 <= index ? '#2688EB' : '#DFDFDF'
                            }}/>
                        <View
                            style={{
                                height: 4.5,
                                width: width/3.5,
                                borderRadius: 20,
                                backgroundColor: 3 <= index ? '#2688EB' : '#DFDFDF'
                            }}/>   
                    </View>
                    <View style={{paddingTop: 15}}>
                        <View style={{height: .6, backgroundColor: 'black'}}/>
                    </View>
                </View>
            </View>
            <FlatList
                    scrollEnabled={false}
                    ref={ref}
                    data={data}
                    horizontal
                    pagingEnabled
                    contentContainerStyle={{flexGrow: 1}}
                    renderItem={({item}) => {
                        return <View style={{width, flex: 1}}>
                                <item.screen handleState={(obj) => {
                                    item.handleState(obj);
                                }}/>
                            </View>
                    }}/>
        </View>
    )
}

export default FillCompanyDataScreen;