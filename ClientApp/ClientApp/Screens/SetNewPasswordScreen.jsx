import React from "react";
import {
    View,
    Text,
    TouchableOpacity
} from 'react-native';
import CustomTextInput from "../Components/CustomTextInput";
import { Icon } from "react-native-elements";
import PasswordBox from "../Components/PasswordBox";
import styles from "../Styles";
import authService from "../services/authService";

const SetNewPasswordScreen = ({navigation, route}) => {
    const token = route.params.token;

    const [password, setPassword] = React.useState('');
    const [confirmPassword, setConfirmPassword] = React.useState('');

    return (
        <View
            style={{
                flex: 1,
                backgroundColor: 'white',
                paddingHorizontal: 15
            }}>
            <Text
                style={{
                    color: '#313131',
                    fontSize: 24,
                    fontWeight: '700',
                    paddingTop: 20
                }}>
                Установите новый пароль    
            </Text>
            <Text
                style={{
                    fontWeight: '400',
                    fontSize: 14,
                    color: '#6D7885',
                    paddingTop: 20,
                    paddingBottom: 5
                }}>
                Пароль
            </Text>
            <PasswordBox
                value={password}
                changed={setPassword}/>

            <Text
                style={{
                    fontWeight: '400',
                    fontSize: 14,
                    color: '#6D7885',
                    paddingTop: 20,
                    paddingBottom: 5
                }}>
                Повторите пароль
            </Text>
            <PasswordBox
                value={confirmPassword}
                changed={setConfirmPassword}
                error={password != '' && password != confirmPassword}/>
            <View
                style={{
                    paddingTop: 20
                }}>
                <TouchableOpacity
                    style={[styles.button, {
                        backgroundColor: 
                            password == '' || 
                            confirmPassword == '' || 
                            password != confirmPassword ? '#ABCDf3' : '#2D81E0'
                    }]}
                    disabled={
                        password == '' || 
                        confirmPassword == '' || 
                        password != confirmPassword
                    }
                    onPress={async () => {
                        await authService.setNewPassword(password, token);
                        navigation.navigate('Login');
                    }}>
                    <Text
                        style={styles.buttonText}>
                        Сохранить новый пароль    
                    </Text>
                </TouchableOpacity> 
            </View>
        </View>
    )
}

export default SetNewPasswordScreen;