import React from 'react';
import {
    View,
    Text,
    TextInput,
    Dimensions,
    ScrollView,
    Modal,
    TouchableOpacity
} from 'react-native';
import styles from '../Styles';
import { Icon, Tooltip } from 'react-native-elements';
import authService from '../services/authService';
import categoryStore from '../services/categoryStore';
import CustomTextInput from '../Components/CustomTextInput';
import PasswordBox from '../Components/PasswordBox';
import ErrorModal from './ErrorModal';

const RegisterScreen = ({navigation, route}) => {
    const { type } = route.params;

    const { width, height } = Dimensions.get('screen');

    const [modalVisible, setModalVisible] = React.useState(false);

    const [firstName, setFirstName] = React.useState('');
    const [lastName, setLastName] = React.useState('');
    const [title, setTitle] = React.useState('');
    const [phone, setPhone] = React.useState('');
    const [email, setEmail] = React.useState('');
    const [address, setAddress] = React.useState('');
    const [password, setPassword] = React.useState('');
    const [confirmPassword, setConfirmPassword] = React.useState('');
    const [emailError, setEmailError] = React.useState(false);
    const [emailValidationError, setEmailValidationError] = React.useState(false);
    const [phoneError, setPhoneError] = React.useState(false);
    const [phoneValidationError, setPhoneValidationError] = React.useState(false);
    const [addressError, setAddressError] = React.useState(false);
    const [weakPasswordError, setWeakPasswordError] = React.useState(false);
    const [passwordsNotMatchedError, setPasswordsNotMatchedError] = React.useState(false);

    const [errorModalVisible, setErrorModalVisible] = React.useState(false);
    const [disable, setDisable] = React.useState(true);

    const updateState = (state, errors) => {
        setDisable(state.includes('') || errors.some(e => e));
    }

    return (
        <ScrollView
            style={{
                flex: 1,
                backgroundColor: 'white',
                paddingHorizontal: 20
            }}
            showsVerticalScrollIndicator={false}>
            <ErrorModal
                visible={errorModalVisible}
                hide={() => setErrorModalVisible(false)}/>
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
                                    {type == 'client' ? 'Аккаунт создан' : 'Аккаунт компании создан'}
                                </Text>
                                <Text 
                                    style={{
                                        paddingTop: 10,
                                        color: '#6D7885',
                                        fontSize: 14,
                                        fontWeight: '400',
                                        alignSelf: 'center'
                                    }}>
                                    {type == 'client' ? 'Теперь вы можете создавать заказы' : 'Заполните информацию о вашей компании'}    
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
                                            setModalVisible(false);
                                            if (type == 'client') {
                                                navigation.goBack();
                                            }
                                            else {
                                                await authService.loginByEmail(email, password);
                                                await categoryStore.retrieveData();
                                                
                                                navigation.navigate('FillCompanyData', {
                                                    email,
                                                    password
                                                });
                                            }
                                        }}>
                                        <Text style={styles.buttonText}>
                                            {type == 'client' ? 'Ок' : 'Заполнить информацию'}
                                        </Text>
                                    </TouchableOpacity>
                                </View>
                            </View>
                        </View>
                    </View>
                </View>
            </Modal>
            <Text
                style={{
                    color: '#313131',
                    fontWeight: '700',
                    fontSize: 24,
                    paddingTop: 30
                }}>
                {type == 'client' ? 'Регистрация клиента' : 'Регистрация компании'}
            </Text>
            <View
                style={{
                    paddingTop: 20
                }}>
                {
                    type == 'client' ?
                    <>
                        <Text
                            style={{
                                color: '#6D7885', 
                                fontWeight: '400', 
                                fontSize: 14, 
                                paddingBottom: 5
                            }}>
                            Имя        
                        </Text>
                        <View style={{paddingBottom: 20}}>
                            <CustomTextInput 
                                value={firstName}
                                placeholder='Введите имя' 
                                changed={(text) => {
                                    setFirstName(text);
                                    updateState([
                                        text, 
                                        lastName, 
                                        email, 
                                        phone, 
                                        address, 
                                        password, 
                                        confirmPassword]);
                                }}/>
                        </View>
                        <Text
                            style={{
                                color: '#6D7885', 
                                fontWeight: '400', 
                                fontSize: 14, 
                                paddingBottom: 5
                            }}>
                            Фамилия        
                        </Text>
                        <View style={{paddingBottom: 20}}>
                            <CustomTextInput 
                                placeholder='Введите фамилию'
                                value={lastName} 
                                changed={(text) => {
                                    setLastName(text);
                                    updateState([
                                        firstName, 
                                        text, 
                                        email, 
                                        phone, 
                                        address, 
                                        password, 
                                        confirmPassword]);
                                }}/>
                        </View>
                    </>
                    :
                    <>
                        <Text
                            style={{
                                color: '#6D7885', 
                                fontWeight: '400', 
                                fontSize: 14, 
                                paddingBottom: 5
                            }}>
                            Название        
                        </Text>
                        <View style={{paddingBottom: 20}}>
                            <CustomTextInput
                                value={title} 
                                placeholder='Введите название компании'
                                changed={(text) => {
                                    setTitle(text);
                                    updateState([
                                        text,
                                        email, 
                                        phone, 
                                        address, 
                                        password, 
                                        confirmPassword], [emailValidationError, phoneValidationError]);
                                }}/>
                        </View>    
                    </>
                }
                <Text
                    style={{
                        color: '#6D7885', 
                        fontWeight: '400', 
                        fontSize: 14, 
                        paddingBottom: 5
                    }}>
                    E-mail        
                </Text>
                <View style={{paddingBottom: 20}}>
                    <CustomTextInput 
                        value={email}
                        error={emailValidationError || emailError}
                        placeholder='Введите E-mail' 
                        changed={(text) => {
                            setEmail(text);
                            let state = [
                                text,
                                phone,
                                address,
                                password,
                                confirmPassword
                            ]

                            const errors = [
                                addressError,
                                weakPasswordError,
                                passwordsNotMatchedError
                            ];

                            if (text != '') {
                                var regex = new RegExp(/^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/);
                                let error = !regex.test(text);
                                errors.push(error);
                                setEmailValidationError(error);
                            }
                            else {
                                setEmailValidationError(false);
                            }

                            if (type == 'client') {
                                state.push(firstName);
                                state.push(lastName)
                            }
                            else {
                                state.push(title);
                            }

                            updateState(state, errors);
                        }}/>
                    {emailError ?
                    <>
                        <Text
                            style={{
                                color: '#E64646',
                                fontWeight: '400',
                                fontSize: 13,
                                paddingTop: 5
                            }}>
                            E-mail уже используется
                        </Text>
                    </>
                    :
                    <>
                    </>}
                </View>
                <Text
                    style={{
                        color: '#6D7885', 
                        fontWeight: '400', 
                        fontSize: 14, 
                        paddingBottom: 5
                    }}>
                    Телефон        
                </Text>
                <View style={{paddingBottom: 20}}>
                    <CustomTextInput
                        value={phone}
                        max={10}
                        type={'phone-pad'}
                        error={phoneValidationError || phoneError} 
                        placeholder='+7 (999) 999-99-99' 
                        changed={(text) => {
                            setPhone(text);
                            let state = [
                                email,
                                text,
                                address,
                                password,
                                confirmPassword
                            ]

                            const errors = [
                                addressError,
                                weakPasswordError,
                                passwordsNotMatchedError,
                            ];

                            if (text != '') {
                                var regex = new RegExp(/\d{10,10}/);
                                let error = !regex.test(text);
                                errors.push(error);
                                setPhoneValidationError(error);
                            }
                            else {
                                setPhoneValidationError(false);
                            }

                            if (type == 'client') {
                                state.push(firstName);
                                state.push(lastName)
                            }
                            else {
                                state.push(title);
                            }

                            updateState(state, errors);
                        }}/>
                    {phoneError ?
                    <>
                        <Text
                            style={{
                                color: '#E64646',
                                fontWeight: '400',
                                fontSize: 13,
                                paddingTop: 5
                            }}>
                            Телефон уже используется
                        </Text>
                    </>
                    :
                    <>
                    </>}
                </View>
                <View
                    style={{
                        flexDirection: 'row'
                    }}>
                    <Text
                        style={{
                            color: '#6D7885', 
                            fontWeight: '400', 
                            fontSize: 14, 
                            paddingBottom: 5,
                            alignSelf: 'center'
                        }}>
                        Адрес
                    </Text>
                    <View
                        style={{
                            paddingLeft: 5,
                            alignSelf: 'center'
                        }}>
                        <Tooltip
                            backgroundColor='#2D81E0'
                            width={300}
                            height={'auto'}
                            popover={
                                <Text
                                    style={{
                                        fontWeight: '400',
                                        fontSize: 13,
                                        color: 'white'
                                    }}>
                                    {'Для того чтобы мы лучше определили Ваше местоположение\nвводите свой адрес в таком формате: {Город},{Улица} {Номер дома}'} 
                                </Text>
                            }>
                            <View
                                style={{
                                    borderRadius: 360,
                                    backgroundColor: '#2D81E0',
                                    padding: 2
                                }}>
                                <Icon
                                    type='material'
                                    color='white'
                                    size={10}
                                    name='question-mark'/>
                            </View>
                        </Tooltip>
                    </View>
                </View>
                <View style={{paddingBottom: 20}}>
                    <CustomTextInput 
                        placeholder='Введите адрес'
                        error={addressError}
                        value={address}
                        big 
                        changed={(text) => {
                            setAddress(text);
                            let state = [
                                email,
                                phone,
                                text,
                                password,
                                confirmPassword
                            ]

                            const errors = [
                                emailValidationError,
                                weakPasswordError,
                                addressError,
                                passwordsNotMatchedError
                            ];

                            if (text != '') {
                                var regex = new RegExp(/^[А-Яа-яЁё\s\-]+,[А-Яа-яЁё0-9\s\-]+$/);
                                let error = !regex.test(text);
                                errors.push(error);
                                setAddressError(error);
                            }
                            else {
                                setAddressError(false);
                            }

                            if (type == 'client') {
                                state.push(firstName);
                                state.push(lastName)
                            }
                            else {
                                state.push(title);
                            }

                            updateState(state, errors);
                        }}/>
                </View>
                <View
                    style={{
                        flexDirection: 'row'
                    }}>
                    <Text
                        style={{
                            color: '#6D7885', 
                            fontWeight: '400', 
                            fontSize: 14, 
                            paddingBottom: 5,
                            alignSelf: 'center'
                        }}>
                        Пароль
                    </Text>
                    <View
                        style={{
                            paddingLeft: 5,
                            alignSelf: 'center'
                        }}>
                        <Tooltip
                            backgroundColor='#2D81E0'
                            height={150}
                            width={200}
                            popover={
                                <Text
                                    style={{
                                        fontWeight: '400',
                                        fontSize: 13,
                                        color: 'white'
                                    }}>
                                    {'-Минимум 8 символов\n-Минимум один символ в верхнем регистре\n-Минимум один символ в нижнем регистре\n-Минимум один цифровой символ\n-Минимум один спец символ'} 
                                </Text>
                            }>
                            <View
                                style={{
                                    borderRadius: 360,
                                    backgroundColor: '#2D81E0',
                                    padding: 2
                                }}>
                                <Icon
                                    type='material'
                                    color='white'
                                    size={10}
                                    name='question-mark'/>
                            </View>
                        </Tooltip>
                    </View>
                </View>
                <View style={{paddingBottom: 20}}>
                    <PasswordBox 
                        value={password}
                        error={weakPasswordError}
                        changed={(text) => {
                            setPassword(text);
                            let state = [
                                email,
                                phone,
                                address,
                                text,
                                confirmPassword
                            ]
                            
                            const errors = [
                                emailValidationError,
                                addressError,
                                passwordsNotMatchedError,
                                phoneValidationError
                            ];

                            if (text != '') {
                                var regex = new RegExp(/^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*()_+={}\[\]:;"'|<>?,.]).{8,16}$/);
                                let error = !regex.test(text);
                                errors.push(error);
                                setWeakPasswordError(error);
                            }
                            else {
                                setWeakPasswordError(false);
                            }

                            if (type == 'client') {
                                state.push(firstName);
                                state.push(lastName)
                            }
                            else {
                                state.push(title);
                            }

                            updateState(state, errors);
                        }}/>
                </View>
                <Text
                    style={{
                        color: '#6D7885', 
                        fontWeight: '400', 
                        fontSize: 14, 
                        paddingBottom: 5
                    }}>
                    Повторите пароль        
                </Text>
                <View style={{paddingBottom: 20}}>
                    <PasswordBox 
                        value={confirmPassword}
                        error={passwordsNotMatchedError}
                        changed={(text) => {
                            setConfirmPassword(text);
                            let state = [
                                email,
                                phone,
                                address,
                                password,
                                text
                            ]

                            const errors = [
                                emailValidationError,
                                addressError,
                                weakPasswordError,
                                phoneValidationError
                            ];

                            if (text != '') {
                                let error = text != password;
                                errors.push(error);
                                setPasswordsNotMatchedError(error);
                            }
                            else {
                                setPasswordsNotMatchedError(false);
                            }

                            if (type == 'client') {
                                state.push(firstName);
                                state.push(lastName)
                            }
                            else {
                                state.push(title);
                            }

                            updateState(state, errors);
                        }}/>
                </View>
                <View>
                    <TouchableOpacity 
                        style={[styles.button, {backgroundColor: disable ? '#ABCDf3' : '#2D81E0'}]}
                        disabled={disable}
                        onPress={async () => {
                            let name = type == 'client' ? `${firstName}_${lastName}` : title;
                            let userType = type == 'client' ? 1 : 2;

                            if (!address.includes(',') || password != confirmPassword) {
                                return;
                            }

                            let addresses = address.split(',');

                            let result = await authService.register(
                                name, 
                                email, 
                                phone, 
                                addresses[1], 
                                addresses[0],
                                password,
                                userType);
                            
                            let emailError = false;
                            let phoneError = false;

                            if (result[1].errors != undefined) {
                                emailError = result[1].errors.email != undefined;
                                phoneError = result[1].errors.phoneNumber != undefined;
                            }

                            if (emailError || phoneError) {
                                setEmailError(emailError);
                                setPhoneError(phoneError);

                                return;
                            }

                            if (result[0] != 200) {
                                setErrorModalVisible(true);
                                return;
                            }

                            setModalVisible(true);
                        }}>
                        <Text style={styles.buttonText}>
                            Создать аккаунт        
                        </Text>
                    </TouchableOpacity>
                </View>
                <View style={{paddingBottom: 20}}>
                    <Text
                        style={{
                            fontSize: 16,
                            fontWeight: '400',
                            color: '#9C9C9C',
                            alignSelf: 'center',
                            paddingTop: 20
                        }}>
                        У вас есть аккаунт
                    </Text>
                    <TouchableOpacity
                        style={{
                            backgroundColor: 'transparent',
                            justifyContent: 'center'
                        }}
                        onPress={() => navigation.goBack()}>
                        <Text 
                            style={{
                                color: '#2D81E0',
                                fontSize: 16,
                                fontWeight: '400',
                                alignSelf: 'center'
                            }}>
                            Войти
                        </Text>
                    </TouchableOpacity>
                </View>
            </View>
        </ScrollView>
    )
}

export default RegisterScreen;