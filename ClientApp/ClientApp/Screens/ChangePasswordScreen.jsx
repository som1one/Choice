import React from 'react';
import {
    View,
    Text,
    TouchableOpacity,
    Dimensions,
    TextInput,
    Modal
} from 'react-native';
import { Icon } from 'react-native-elements';
import styles from '../Styles';
import authService from '../services/authService';
import CustomTextInput from '../Components/CustomTextInput';
import PasswordBox from '../Components/PasswordBox';

const ChangePasswordScreen = ({ navigation }) => {
    const { width, height } = Dimensions.get('screen');

    const [oldPassword, setOldPassword] = React.useState('');
    const [password, setPassword] = React.useState('');
    const [confirmPassword, setConfirmPassword] = React.useState('');

    const [hideOldPassword, setHideOldPassword] = React.useState(true);
    const [hidePassword, setHidePassword] = React.useState(true);
    const [hideConfirmPassword, setHideConfirmPassword] = React.useState(true);

    const [disable, setDisable] = React.useState(true);
    const [modalVisible, setModalVisible] = React.useState(false);

    const updateState = (state) => {
        if (state.password != '' && state.oldPassword != '' && state.confirmPassword != '') {
            setDisable(false);
        }
        else {
            setDisable(true);
        }
    }

    const changePassword = async () => {
        if (password == confirmPassword) {
            await authService.changePassword(oldPassword, password);
            setModalVisible(true);
        }
    }

    return (
        <View style={{flex: 1, backgroundColor: 'white'}}>
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
                                    Пароль изменен
                                </Text>
                                <View
                                    style={{
                                        paddingTop: 40,
                                        paddingBottom: 10,
                                        paddingHorizontal: 10
                                    }}>
                                    <TouchableOpacity 
                                        style={[styles.button, {borderRadius: 10}]}
                                        onPress={() => {
                                            navigation.goBack();
                                        }}>
                                        <Text style={styles.buttonText}>Ок</Text>
                                    </TouchableOpacity>
                                </View>
                            </View>
                        </View>
                    </View>
                </View>
            </Modal>
            <View style={{flexDirection: 'row', justifyContent: 'space-between', paddingTop: 20}}>
                <TouchableOpacity 
                    style={{alignSelf: 'center'}}
                    onPress={() => navigation.goBack()}>
                    <Icon name='chevron-left'
                          type='material'
                          color={'#2688EB'}
                          size={40}/>
                </TouchableOpacity>
                <Text 
                    style={{
                        alignSelf: 'center', 
                        color: 'black', 
                        fontWeight: '600', 
                        fontSize: 21
                    }}>
                    Изменить пароль
                </Text>
                <Text></Text>
            </View>
            <View
                style={{paddingHorizontal: 20, paddingTop: 20, flex: 1}}>
                <Text
                    style={{
                        color: '#6D7885', 
                        fontWeight: '400', 
                        fontSize: 14, 
                        paddingBottom: 5
                    }}>
                    Старый пароль        
                </Text>
                <View style={{paddingBottom: 20}}>
                    <PasswordBox  
                        value={oldPassword} 
                        changed={(text) => {
                            setOldPassword(text);
                            updateState({
                                password,
                                oldPassword: text,
                                confirmPassword
                            });
                        }}/>
                </View>
                <Text
                    style={{
                        color: '#6D7885', 
                        fontWeight: '400', 
                        fontSize: 14, 
                        paddingBottom: 5
                    }}>
                    Новый пароль        
                </Text>
                <View style={{paddingBottom: 20}}>
                    <PasswordBox  
                        value={password} 
                        changed={(text) => {
                            setPassword(text);
                            updateState({
                                password: text,
                                oldPassword,
                                confirmPassword
                            });
                        }}/>
                </View>
                <Text
                    style={{
                        color: '#6D7885', 
                        fontWeight: '400', 
                        fontSize: 14, 
                        paddingBottom: 5
                    }}>
                    Повторите новый пароль        
                </Text>
                <View style={{paddingBottom: 20}}>
                    <PasswordBox  
                        value={confirmPassword} 
                        changed={(text) => {
                            setConfirmPassword(text);
                            updateState({
                                password,
                                oldPassword,
                                confirmPassword: text
                            });
                        }}/>
                </View>
                <View
                    style={{
                        justifyContent: 'flex-end', 
                        flex: 1, 
                        paddingBottom: 10
                    }}>
                    <TouchableOpacity
                        style={[styles.button, { backgroundColor: disable ? '#ABCDf3' : '#2D81E0' }]}
                        disabled={disable}
                        onPress={changePassword}>
                        <Text
                            style={styles.buttonText}>
                            Сохранить новый пароль
                        </Text>
                    </TouchableOpacity>
                </View>    
            </View>
        </View>
    );
}

export default ChangePasswordScreen;