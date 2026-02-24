import React from "react";
import {
    View,
    TouchableOpacity,
    Text
} from 'react-native';
import { Icon } from "react-native-elements";
import CustomTextInput from "../Components/CustomTextInput";
import styles from "../Styles";
import companyService from "../services/companyService";
import authService from "../services/authService";

const ResetPasswordScreen = ({navigation}) => {
    const [email, setEmail] = React.useState('');
    const [emailError, setEmailError] = React.useState(false);
    const [code, setCode] = React.useState('');
    const [codeError, setCodeError] = React.useState(false);

    const [isCodeSent, setIsCodeSent] = React.useState(false);

    const emailChanged = (text) => {
        setEmailError(false);
        setEmail(text);
    }

    const codeChanged = (text) => {
        setCodeError(false);
        setCode(text);
    }

    return (
        <View
            style={{
                flex: 1,
                backgroundColor: 'white',
                paddingHorizontal: 15
            }}>
            <View
                style={{
                    flexDirection: 'row',
                    paddingTop: 20,
                }}>
                <TouchableOpacity
                    style={{
                        alignSelf: 'center'
                    }}
                    onPress={() => navigation.goBack()}>
                    <Icon
                        type="material"
                        name="chevron-left"
                        color="#2688EB"
                        size={35}/>
                </TouchableOpacity>
            </View>
            <Text
                style={{
                    color: 'black',
                    fontSize: 21,
                    fontWeight: '600',
                    alignSelf: 'center',
                    position: 'absolute',
                    paddingTop: 20
                }}>
                Восстановить пароль
            </Text>
            <Text
                style={{
                    color: '#181818',
                    fontWeight: '400',
                    fontSize: 16,
                    paddingTop: 30,
                }}>
                {!isCodeSent ? 
                'Введите ваш e-mail, мы отправим на него\nкод для сброса пароля'
                : 
                `Мы отправили код для сброса пароля на электронную почту: ${email}`}
            </Text>
            <Text
                style={{
                    fontWeight: '400',
                    fontSize: 14,
                    color: '#6D7885',
                    paddingTop: 20,
                    paddingBottom: 5
                }}>
                {isCodeSent ? 'Код для сброса пароля' : 'E-mail'}
            </Text>
            <CustomTextInput
                value={isCodeSent ? code : email}
                changed={isCodeSent ? codeChanged : emailChanged}
                placeholder={isCodeSent ? '000-000' : 'Введите E-mail'}
                max={isCodeSent ? 6 : undefined}
                type={isCodeSent ? 'numeric' : 'email-address'}
                error={isCodeSent ? codeError : emailError}/>

            {emailError || codeError ?
            <>
                <Text
                    style={{
                        color: '#E64646',
                        fontWeight: '400',
                        fontSize: 13,
                        paddingTop: 5
                    }}>
                    {isCodeSent ? 'Неверный код' : 'Нету аккаунта с таким email'}
                </Text>
            </>
            :
            <>
            </>}

            <View
                style={{
                    paddingTop: 20
                }}>
                <TouchableOpacity
                    style={[styles.button, {
                        backgroundColor: email == '' ? '#ABCDf3' : '#2D81E0'
                    }]}
                    disabled={email == ''}
                    onPress={async () => {
                        if (!isCodeSent) {
                            let status = await authService.resetPassword(email);
                            if (status == 200) {
                                setIsCodeSent(true);
                            }
                            else {
                                setEmailError(true);
                            }
                        }
                        else {
                            let result = await authService.verifyPasswordReset(email, code);
                            
                            if (result[0] == 200) {
                                setCode('');
                                setEmail('');
                                setIsCodeSent(false);
                                navigation.navigate('SetNewPassword', { token: result[1] });
                            }
                            else {
                                setCodeError(true);
                            }
                        }
                    }}>
                    <Text
                        style={styles.buttonText}>
                        {isCodeSent ? 'Сбросить пароль' : 'Отправить код'}    
                    </Text>
                </TouchableOpacity>    
            </View>
        </View>
    )
}

export default ResetPasswordScreen;