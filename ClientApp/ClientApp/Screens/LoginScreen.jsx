import React from "react";
import LoginByEmailScreen from "./LoginByEmailScreen";
import LoginByPhoneScreen from "./LoginByPhoneScreen";
import {
  Image,
  SafeAreaView,
  View,
  Text,
  findNodeHandle,
  Animated,
  FlatList,
  Dimensions,
  TouchableOpacity,
  KeyboardAvoidingView,
  Modal
} from 'react-native';
import RNFS from 'react-native-fs';
import Tabs from "../Components/Tabs";
import { AuthContext } from "../App";
import ActionSheet from "react-native-actions-sheet";
import styles from "../Styles";

const screens = {
  loginByEmail: { screen: LoginByEmailScreen, title: 'E-mail' },
  loginByPhone: { screen: LoginByPhoneScreen, title: 'Телефон' }
};

const {width, height} = Dimensions.get('screen');  
const data = Object.keys(screens).map((i) => ({
    key: i,
    title: screens[i].title,
    screen: screens[i].screen,
    ref: React.createRef()
}));

export default function LoginScreen({ navigation, route }) {
    const { signIn } = React.useContext(AuthContext);
    const [modalVisible, setModalVisible] = React.useState(false);

    const scrollX = React.useRef(new Animated.Value(0)).current;
    const ref = React.useRef();
    const onItemPress = React.useCallback(itemIndex => {
        ref?.current?.scrollToOffset({
            offset: itemIndex * width
        });
    });

    return (
        <KeyboardAvoidingView
            behavior="position"
            keyboardVerticalOffset={0} 
            style={{
                flex: 1, 
                flexDirection: 'column', 
                justifyContent: 'center', 
                backgroundColor: 'white',
                width,
                position: 'absolute'
            }}>
            <Modal
                visible={modalVisible}
                transparent={true}
                animationType="slide">
                <View
                    style={{
                        flex: 1,
                        backgroundColor: 'rgba(0,0,0,0.5)',
                        justifyContent: 'flex-end'
                    }}>
                    <View
                        style={{
                            paddingHorizontal: 15,
                            paddingBottom: 20
                        }}>
                        <TouchableOpacity
                            style={{
                                height: height/13,
                                backgroundColor: 'white',
                                borderTopLeftRadius: 20,
                                borderTopRightRadius: 20,
                                borderBottomColor: '#0000001F',
                                borderBottomWidth: .5,
                                justifyContent: 'center',
                            }}
                            activeOpacity={.8}
                            onPress={() => {
                                setModalVisible(false);
                                navigation.navigate('Register', { type: 'client' })
                            }}>
                            <Text
                                style={{
                                    color: '#2688EB',
                                    fontWeight: '400',
                                    fontSize: 20,
                                    alignSelf: 'center'
                                }}>
                                Создать аккаунт клиента
                            </Text>    
                        </TouchableOpacity>
                        <TouchableOpacity
                            style={{
                                height: height/13,
                                backgroundColor: 'white',
                                borderBottomLeftRadius: 20,
                                borderBottomRightRadius: 20,
                                justifyContent: 'center'
                            }}
                            activeOpacity={.8}
                            onPress={() => {
                                setModalVisible(false);
                                navigation.navigate('Register', { type: 'company' })
                            }}>
                            <Text
                                style={{
                                    color: '#2688EB',
                                    fontWeight: '400',
                                    fontSize: 20,
                                    alignSelf: 'center'
                                }}>
                                Создать аккаунт компании
                            </Text>     
                        </TouchableOpacity>
                        <View
                            style={{
                                paddingTop: 10
                            }}>
                            <TouchableOpacity
                                style={{
                                    justifyContent: 'center',
                                    backgroundColor: 'white',
                                    borderRadius: 20,
                                    height: height/13,
                                }}
                                activeOpacity={.8}
                                onPress={() => setModalVisible(false)}>
                                <Text
                                    style={{
                                        color: '#2688EB',
                                        fontWeight: '500',
                                        fontSize: 20,
                                        alignSelf: 'center'
                                    }}>
                                    Отменить
                                </Text>     
                            </TouchableOpacity>
                        </View>
                    </View>
                </View>
            </Modal>
            <View style={{alignSelf: 'center', paddingTop: 20}}>
                <Image style={{width: 150, height: 150, resizeMode: 'contain', alignSelf: 'center'}}
                       source={require("../assets/choice-logo.png")}/>
                <Text style={{fontSize: 20, color: '#313131', fontWeight: '600', alignSelf: 'center', paddingTop: 20}}>ВЫБОР</Text>
                <Text style={{fontSize: 16, paddingTop: 10}}>Приложение для выбора</Text>
                <Text style={{fontSize: 16, alignSelf: 'center'}}>лучших условий</Text>
            </View>
            <View style={{flexDirection: 'row', paddingHorizontal: 20, paddingTop: 40}}>
                <Text style={{fontSize: 24, fontWeight: '700', color: '#313131'}}>Авторизация</Text>
                <View style={{flex: 1, justifyContent: 'flex-end', flexDirection: 'row'}}>
                    <TouchableOpacity 
                        style={{alignSelf: 'center'}}
                        onPress={() => setModalVisible(true)}>
                        <Text style={{color: '#2D81E0', fontSize: 16, fontWeight: '400'}}>Создать аккаунт</Text>
                    </TouchableOpacity>
                </View>
            </View>
            <View
                style={{
                    paddingTop: 10
                }}>
                <Tabs 
                    scrollX={scrollX} 
                    data={data} 
                    onItemPress={onItemPress} 
                    admin={false}/>
            </View>
            <Animated.FlatList data={data}
                               ref={ref}
                               keyExtractor={(item) => item.key}
                               horizontal
                               pagingEnabled
                               bounces={false}
                               onScroll={Animated.event(
                                [{nativeEvent: {contentOffset: {x: scrollX}}}],
                                { useNativeDriver: false }
                               )}
                               showsHorizontalScrollIndicator={false}
                               renderItem={({item}) => {
                               return <View style={{width,paddingTop: 30}}>
                                 <item.screen navigation={navigation} signIn={signIn}/>
                               </View>
                            }}/>
            <View
                style={{
                    paddingTop: 30
                }}>
                <TouchableOpacity
                    style={{
                        backgroundColor: 'transparent',
                        justifyContent: 'center'
                    }}
                    onPress={() => navigation.navigate('ResetPassword')}>
                    <Text
                        style={{
                            color: '#2D81E0',
                            fontSize: 16,
                            fontWeight: '400',
                            alignSelf: 'center'
                        }}>
                        Я забыл пароль
                    </Text>
                </TouchableOpacity>
            </View>
        </KeyboardAvoidingView>
    )
}