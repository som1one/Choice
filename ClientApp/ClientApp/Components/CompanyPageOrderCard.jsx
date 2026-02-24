import React from "react";
import {
    View,
    Text,
    TouchableOpacity
} from 'react-native';
import { Icon } from "react-native-elements";
import styles from "../Styles";
import dateHelper from "../helpers/dateHelper";

const CompanyPageOrderCard = ({navigation, message}) => {
    return (
        <View
            style={{
                backgroundColor: '#2D81E0',
                borderRadius: 15,
                paddingHorizontal: 10
            }}>
            <Text
                style={{
                    fontWeight: '600',
                    fontSize: 14,
                    color: 'white',
                    paddingTop: 10
                }}>
                Ответ компании на Ваш запрос    
            </Text>
            {
                JSON.parse(message.body).Price > 0 ?
                <>
                    <View
                        style={{
                            flexDirection: 'row',
                            justifyContent: 'space-between',
                            paddingHorizontal: 10
                        }}>
                        <View 
                            style={{
                                flexDirection: 'row',
                                paddingTop: 10
                            }}>
                            <Icon
                                type='material'
                                name='currency-ruble'
                                size={15}
                                color='#ADCBEB'
                                style={{alignSelf: 'center'}}/>
                            <Text
                                style={{
                                    fontSize: 14,
                                    fontWeight: '400',
                                    color: '#ADCBEB',
                                    alignSelf: 'center',
                                    paddingLeft: 5
                                }}>
                                Стоимость
                            </Text>
                        </View>
                        <Text
                            style={{
                                color: 'white',
                                fontSize: 14,
                                fontWeight: '500',
                                alignSelf: 'center'
                            }}>
                            {`${JSON.parse(message.body).Price} рублей`}        
                        </Text>
                    </View>
                </>
                :
                <>
                </>
            }
            {
                JSON.parse(message.body).Deadline > 0 ?
                <>
                    <View
                        style={{
                            flexDirection: 'row',
                            justifyContent: 'space-between',
                            paddingHorizontal: 10
                        }}>
                        <View 
                            style={{
                                flexDirection: 'row',
                                paddingTop: 10
                            }}>
                            <Icon
                                type='material'
                                name='schedule'
                                size={15}
                                color='#ADCBEB'
                                style={{alignSelf: 'center'}}/>
                            <Text
                                style={{
                                    fontSize: 14,
                                    fontWeight: '400',
                                    color: '#ADCBEB',
                                    alignSelf: 'center',
                                    paddingLeft: 5
                                }}>
                                Время выполнения работы
                            </Text>
                        </View>
                        <Text
                            style={{
                                color: 'white',
                                fontSize: 14,
                                fontWeight: '500',
                                alignSelf: 'center'
                            }}>
                            {`${JSON.parse(message.body).Deadline} часов`}        
                        </Text>
                    </View>
                </>
                :
                <>
                </>
            }
            {
                JSON.parse(message.body).EnrollmentTime != null ?
                <>
                    <View
                        style={{
                            flexDirection: 'row',
                            justifyContent: 'space-between',
                            paddingHorizontal: 10
                        }}>
                        <View 
                            style={{
                                flexDirection: 'row',
                                paddingTop: 10
                            }}>
                            <Icon
                                type='material'
                                name='calendar-today'
                                size={15}
                                color='#ADCBEB'
                                style={{alignSelf: 'center'}}/>
                            <Text
                                style={{
                                    fontSize: 14,
                                    fontWeight: '400',
                                    color: '#ADCBEB',
                                    alignSelf: 'center',
                                    paddingLeft: 5
                                }}>
                                Дата и время записи
                            </Text>
                        </View>
                        <Text
                            style={{
                                color: 'white',
                                fontSize: 14,
                                fontWeight: '500',
                                alignSelf: 'center'
                            }}>
                            {dateHelper.formatDate(JSON.parse(message.body).EnrollmentTime)}        
                        </Text>
                    </View>
                </>
                :
                <>
                </>
            }
            <View
                style={{
                    flexDirection: 'row',
                    justifyContent: 'space-between',
                    paddingHorizontal: 10
                }}>
                <View 
                    style={{
                        flexDirection: 'row',
                        paddingTop: 10
                    }}>
                    <Icon
                        type='material'
                        name='payments'
                        size={15}
                        color='#ADCBEB'
                        style={{alignSelf: 'center'}}/>
                    <Text
                        style={{
                            fontSize: 14,
                            fontWeight: '400',
                            color: '#ADCBEB',
                            alignSelf: 'center',
                            paddingLeft: 5
                        }}>
                        Предоплата
                    </Text>
                </View>
                <Text
                    style={{
                        color: 'white',
                        fontSize: 14,
                        fontWeight: '500',
                        alignSelf: 'center'
                    }}>
                    {JSON.parse(message.body).Prepayment > 0 ? 'Нужна' : 'Не нужна'}        
                </Text>
            </View>
            <View
                style={{paddingTop: 20, paddingBottom: 10}}>
                <TouchableOpacity
                    style={[styles.button, {backgroundColor: 'white'}]}
                    onPress={() => {
                        navigation.navigate('Chat', {chatId: message.senderId})
                    }}>
                    <Text
                        style={[styles.buttonText, {color: '#2C2D2E'}]}>
                        Перейти в чат с компанией
                    </Text>
                </TouchableOpacity>   
            </View>
        </View>
    )
}

export default CompanyPageOrderCard;