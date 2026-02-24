import React from "react";
import {
    View,
    TouchableOpacity,
    Text,
    Image,
    KeyboardAvoidingView
} from 'react-native';
import { Icon } from "react-native-elements";
import env from "../env";
import CustomTextInput from "../Components/CustomTextInput";
import styles from "../Styles";
import * as ImagePicker from 'react-native-image-picker';
import blobService from "../services/blobService";
import categoryService from "../services/categoryService";

const EditCategoryScreen = ({navigation, route}) => {
    const { category } = route.params;
    const defaultUri = `${env.api_url}/api/objects/${category.iconUri}`;

    const [title, setTitle] = React.useState(category.title);
    const [uri, setUri] = React.useState(defaultUri);
    const [isEditMode, setIsEditMode] = React.useState(false);

    return (
        <View
            style={{
                flex: 1,
                backgroundColor: 'white'
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
                {category.id >= 1 && category.id <= 7 ?
                <>
                    <Text></Text>
                </>
                :
                <>
                    <TouchableOpacity
                        onPress={() => {
                            if (isEditMode) {
                                setTitle(category.title);
                                setUri(defaultUri);
                            }

                            setIsEditMode(prev => !prev);
                        }}
                        style={{
                            alignSelf: 'center'
                        }}>
                        <Icon
                            name={isEditMode ? 'close' : 'edit'}
                            type='material'
                            color='#2688EB'
                            size={25}/>
                    </TouchableOpacity>
                </>}
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
                Категория
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
                        source={{uri}}
                        style={{
                            alignSelf: 'center',
                            height: 30,
                            width: 30 
                        }}/>
                </View>
            </View>
            <View
                style={{
                    paddingTop: 20
                }}>
                <TouchableOpacity
                    disabled={(category.id >= 1 && category.id <= 7) || !isEditMode}
                    onPress={async () => {
                        let response = await ImagePicker.launchImageLibrary();

                        if (!response.didCancel) {
                            setUri(response.assets[0].uri);
                        }
                    }}>
                    <Text
                        style={{
                            fontSize: 15,
                            fontWeight: '500',
                            color: !(category.id >= 1 && category.id <= 7) && isEditMode ? '#2D81E0' : '#ABCDf3',
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
                    changed={setTitle}
                    readonly={(category.id >= 1 && category.id <= 7) || !isEditMode}/>
            </View>
            {!(category.id >= 1 && category.id <= 7) && isEditMode ?
            <>
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
                            backgroundColor: title != '' ? '#2D81E0' : '#ABCDf3'
                        }]}
                        disabled={title == ''}
                        onPress={async () => {
                            let iconUri = '';

                            if (uri != defaultUri) {
                                iconUri = await blobService.uploadImage(uri);
                            }
                            else {
                                iconUri = category.iconUri;
                            }

                            let body = {
                                id: category.id,
                                title,
                                iconUri
                            }

                            let status = await categoryService.update(body);
                            console.log(status);

                            setIsEditMode(false);
                        }}>
                        <Text
                            style={styles.buttonText}>
                            Сохранить изменения
                        </Text>
                    </TouchableOpacity>
                    <View
                        style={{
                            paddingTop: 10
                        }}>
                        <TouchableOpacity
                            style={[styles.button, {
                                backgroundColor: '#0000000D'
                            }]}
                            onPress={async () => {
                                await categoryService.remove(category.id);
                                navigation.goBack();
                            }}>
                            <Text
                                style={[styles.buttonText,{
                                    color: '#EB2626'
                                }]}>
                                Удалить категорию
                            </Text>
                        </TouchableOpacity>
                    </View>
                </KeyboardAvoidingView>
            </>
            :
            <>

            </>}
        </View>
    )
}

export default EditCategoryScreen;