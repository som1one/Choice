import React from "react";
import styles from "../Styles.jsx";
import authService from "../services/authService.js";
import { Icon } from "react-native-elements";
import {
  SafeAreaView,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  Dimensions
} from 'react-native';
import userStore from "../services/userStore.js";
import categoryStore from "../services/categoryStore.js";
import CustomTextInput from "../Components/CustomTextInput.jsx";
import PasswordBox from "../Components/PasswordBox.jsx";

export default function LoginByEmailScreen({navigation, signIn}) {
    const [email, setEmail] = React.useState('');
    const [password, setPassword] = React.useState('');
    const [disabled, setDisabled] = React.useState(true);
    const [error, setError] = React.useState(false);

    const login = async () => {
        setError(false);

        let userType = await authService.loginByEmail(email, password);
        console.log(userType);
        await userStore.retrieveData(userType);

        console.log(userType);

        if (userType[0] == 500) {
            return;
        }

        if (userType != -1) {
            if (userType == 2) {
                let user = userStore.get();

                if (!user.isDataFilled) {
                    await categoryStore.retrieveData();
                    navigation.navigate('FillCompanyData', {
                        email,
                        password
                    });
                }
                else {
                    await signIn(userType);
                }
            }
            else {
                await signIn(userType);
            }
        }
        else {
            setError(true);
        }
    }

    const onEmailChanged = (email) => {
        if (email == '' || password == '') { 
            setDisabled(true);
        }
        else {
            setDisabled(false);
        }

        setEmail(email);
    }

    const onPasswordChanged = (password) => {
        if (email == '' || password == '') { 
            setDisabled(true);
        }
        else {
            setDisabled(false);
        }

        setPassword(password);
    }

    return (
        <SafeAreaView>
             <View style={{paddingHorizontal: 20}}>
                <Text 
                    style={{
                        color: '#6D7885', 
                        fontWeight: '400', 
                        fontSize: 14, 
                        paddingBottom: 5
                    }}>
                    E-mail
                </Text>
                <CustomTextInput
                    value={email}
                    changed={onEmailChanged}
                    placeholder={'E-mail'}
                    error={error}/>
                <Text 
                    style={{
                        color: '#6D7885', 
                        fontWeight: '400', 
                        fontSize: 14, 
                        paddingBottom: 5, 
                        paddingTop: 30
                    }}>
                    Пароль
                </Text>
                <PasswordBox
                    value={password}
                    changed={onPasswordChanged}
                    error={error}/>
                {error ?
                <>
                    <Text
                        style={{
                            color: '#E64646',
                            fontWeight: '400',
                            fontSize: 13,
                            paddingTop: 5
                        }}>
                        Пароль или E-mail неверны
                    </Text>
                </>
                :
                <>
                </>}
                <View 
                    style={{paddingTop: 30}}>
                    <TouchableOpacity 
                        onPress={!disabled && login} 
                        disabled={disabled} 
                        style={[
                            styles.button, {
                                backgroundColor: disabled ? '#ABCDf3' : '#2D81E0'
                            }
                        ]}>
                        <Text 
                            style={styles.buttonText}>
                            Войти
                        </Text>
                    </TouchableOpacity>
                </View>
            </View>
        </SafeAreaView>
    );
}