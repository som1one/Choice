import React from "react";
import {
    View,
    Text,
    TextInput,
    TouchableOpacity,
} from 'react-native';
import styles from "../Styles";
import CustomTextInput from "../Components/CustomTextInput";

const ContactDetailsScreen = ({handleState}) => {
    const [url, setUrl] = React.useState('');

    return (
        <View
            style={{
                backgroundColor: 'white',
                paddingTop: 10,
                flex: 1,
                paddingHorizontal: 20,
            }}>
            <Text
                style={{
                    color: 'black',
                    fontWeight: '700',
                    fontSize: 17
                }}>
                Контактные данные
            </Text>
            <Text
                style={{
                    color: '#181818',
                    fontWeight: '400',
                    fontSize: 16,
                    paddingTop: 20
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
                Сайт        
            </Text>
            <View>
                <CustomTextInput
                    value={url}
                    placeholder="Введите адрес сайта" 
                    changed={(text) => {
                        setUrl(text);
                    }}/>
            </View>
            <View
                style={{
                    flex: 1,
                    justifyContent: 'flex-end',
                    paddingBottom: 10,
                }}>
                <TouchableOpacity
                    style={styles.button}
                    onPress={(() => handleState(url))}>
                    <Text style={styles.buttonText}>
                        Далее
                    </Text>
                </TouchableOpacity>                   
            </View>
        </View>
    )
}

export default ContactDetailsScreen;