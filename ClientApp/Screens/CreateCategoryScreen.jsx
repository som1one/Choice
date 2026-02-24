import React from "react";
import {
    View,
    TouchableOpacity,
    Text,
    Image,
    KeyboardAvoidingView,
    Dimensions
} from 'react-native';
import { Icon } from "react-native-elements";
import env from "../env";
import CustomTextInput from "../Components/CustomTextInput";
import styles from "../Styles";
import * as ImagePicker from 'react-native-image-picker';
import categoryService from "../services/categoryService";
import blobService from "../services/blobService";

const CreateCategoryScreen = ({navigation}) => {
    const defaultUri = `${env.api_url}/api/objects/defaulturi`;
    const { width, height } = Dimensions.get('screen');
    const [title, setTitle] = React.useState('');
    const [uri, setUri] = React.useState(defaultUri);

    return (
        <View
            style={{
                flex: 1,
                backgroundColor: 'white',
            }}>
            <View
                style={{
                    flexDirection: 'row',
                    paddingTop: 10,
                    paddingHorizontal: 10,
                    justifyContent: 'space-between'
                }}>
                <TouchableOpacity
                    style={{
                        alignSelf:'center'
                    }}
                    onPress={() => navigation.goBack()}>
                    <Icon
                        name='chevron-left'
                        type='material'
                        color='#2688EB'
                        size={40}/>
                </TouchableOpacity>  
                <Text></Text>
            </View>
            <Text
                style={{
                    fontWeight: '600',
                    color: 'black',
                    fontSize: 21,
                    alignSelf: 'center',
                    position: 'absolute',
                    top: 15
                }}>
                Создать категорию
            </Text>
            <View
                style={{
                    paddingTop: 20
                }}>
                <View
                    style={{
                        height: 100,
                        width: 100,
                        borderRadius: 360,
                        alignSelf: 'center',
                        justifyContent: 'center',
                        backgroundColor: '#47A4F9'
                    }}>
                    <Image
                        source={{uri: uri}}
                        style={{
                            alignSelf: 'center',
                            height: defaultUri == uri ? 100 : 30,
                            width: defaultUri == uri ? 100 : 30,
                            borderRadius: defaultUri == uri ? 360 : 0 
                        }}/>
                </View>
            </View>
            <View
                style={{
                    paddingTop: 20
                }}>
                <TouchableOpacity
                    onPress={async () => {
                        const response = await ImagePicker.launchImageLibrary();

                        if (!response.didCancel) {
                            let uri = response.assets[0].uri;
                            setUri(uri);
                        }
                    }}>
                    <Text
                        style={{
                            fontSize: 15,
                            fontWeight: '500',
                            color: '#2D81E0',
                            alignSelf: 'center'
                        }}>
                        Изменить иконку    
                    </Text>
                </TouchableOpacity>
            </View>
            <View
                style={{
                    paddingTop: 20,
                    paddingHorizontal: 20
                }}>
                <View
                    style={{
                        borderRadius: 20,
                        paddingHorizontal: 10,
                        backgroundColor: 'white',
                        flexDirection: 'row',
                        shadowColor: 'black',
                        shadowOpacity: 0.1,
                        shadowRadius: 100,
                        elevation: 3,
                        shadowOffset: {
                            width: 50,
                            height: 50
                        }
                    }}>
                    <Icon
                        type='material'
                        name='error'
                        color='#818C99'
                        size={30}
                        style={{
                            alignSelf: 'center',
                            paddingTop: 10,
                            paddingBottom: 10
                        }}/>
                    <Text
                        style={{
                            color: '#6D7885',
                            fontWeight: '400',
                            fontSize: 14,
                            paddingTop: 10,
                            paddingBottom: 10,
                            alignSelf: 'center',
                            paddingLeft: 5
                        }}>
                        {'Иконки PNG на прозрачном фоне.\nЦвет заливки - белый. Стиль - Outline'}
                    </Text>    
                </View>
            </View>
            <View
                style={{
                    paddingHorizontal: 20
                }}>
                <Text
                    style={{
                        color: '#F2F3F5',
                        fontSize: 14,
                        fontWeight: '400',
                        color: '#6D7885',
                        paddingTop: 30,
                        paddingBottom: 5
                    }}>
                    Название категории
                </Text>
                <CustomTextInput
                    value={title}
                    changed={setTitle}/>
            </View>
            <KeyboardAvoidingView
                behavior="position"
                style={{
                    flex: 1,
                    justifyContent: 'flex-end',
                    bottom: 10,
                    paddingHorizontal: 20
                }}>
                <TouchableOpacity
                    style={[styles.button, {
                        backgroundColor: uri == defaultUri || title == '' ? '#ABCDf3' : '#2D81E0'
                    }]}
                    disabled={uri == defaultUri || title == ''}
                    onPress={async () => {
                        let iconUri = await blobService.uploadImage(uri);

                        let status = await categoryService.create({
                            title,
                            iconUri
                        });

                        console.log(status);
                        navigation.goBack();
                    }}>
                    <Text
                        style={styles.buttonText}>
                        Создать категорию
                    </Text>
                </TouchableOpacity>
            </KeyboardAvoidingView>
        </View>
    )
}

export default CreateCategoryScreen;