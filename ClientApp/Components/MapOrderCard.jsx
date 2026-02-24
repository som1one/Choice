import React from 'react';
import {
    View,
    Text
} from 'react-native';
import { Icon } from 'react-native-elements';
import dateHelper from '../helpers/dateHelper';

const MapOrderCard = ({message, company}) => {
    return (
        <View
            style={{
                justifyContent: 'center',
                backgroundColor: 'white',
                borderRadius: 15,
                justifyContent: 'center'
            }}>
            <View
                style={{
                    flexDirection: 'row',
                    paddingLeft: 10,
                    paddingTop: 10
                }}>
                <Text
                    style={{
                        color: '#979797',
                        fontWeight: '500',
                        fontSize: 13,
                        paddingRight: 5
                    }}>
                    {company.title}
                </Text>
                <View
                    style={{
                        backgroundColor: '#979797',
                        width: 1
                    }}/>
                <Icon
                    name='star'
                    type='material'
                    color='yellow'
                    size={20}
                    style={{paddingLeft: 5}}/>
                <Text
                    style={{
                        color: '#979797',
                        fontWeight: '500',
                        fontSize: 13
                    }}>
                    {company.averageGrade}
                </Text>    
            </View>
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
                                color='#3B4147'
                                style={{alignSelf: 'center'}}/>
                            <Text
                                style={{
                                    fontSize: 14,
                                    fontWeight: '400',
                                    color: '#2E2424',
                                    alignSelf: 'center',
                                    paddingLeft: 5
                                }}>
                                Стоимость
                            </Text>
                        </View>
                        <Text
                            style={{
                                color: 'black',
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
                                color='#3B4147'
                                style={{alignSelf: 'center'}}/>
                            <Text
                                style={{
                                    fontSize: 14,
                                    fontWeight: '400',
                                    color: '#2E2424',
                                    alignSelf: 'center',
                                    paddingLeft: 5
                                }}>
                                Время выполнения работы
                            </Text>
                        </View>
                        <Text
                            style={{
                                color: 'black',
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
                                color='#3B4147'
                                style={{alignSelf: 'center'}}/>
                            <Text
                                style={{
                                    fontSize: 14,
                                    fontWeight: '400',
                                    color: '#2E2424',
                                    alignSelf: 'center',
                                    paddingLeft: 5
                                }}>
                                Дата и время записи
                            </Text>
                        </View>
                        <Text
                            style={{
                                color: 'black',
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
            {
                JSON.parse(message.body).Prepayment > 0 ?
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
                                name='payments'
                                size={15}
                                color='#3B4147'
                                style={{alignSelf: 'center'}}/>
                            <Text
                                style={{
                                    fontSize: 14,
                                    fontWeight: '400',
                                    color: '#2E2424',
                                    alignSelf: 'center',
                                    paddingLeft: 5
                                }}>
                                Предоплата
                            </Text>
                        </View>
                        <Text
                            style={{
                                color: 'black',
                                fontSize: 14,
                                fontWeight: '500',
                                alignSelf: 'center'
                            }}>
                            {`${JSON.parse(message.body).Prepayment} рублей`}        
                        </Text>
                    </View>
                </>
                :
                <>
                </>
            }
        </View>
    )
}

export default MapOrderCard;