import React from 'react'
import {
    View,
    Text,
    Dimensions,
    TouchableOpacity,
    Image
} from 'react-native'
import { Icon } from 'react-native-elements';
import dateHelper from '../helpers/dateHelper';
import userStore from '../services/userStore';
import styles from '../Styles';
import env from '../env';

const Message = ({message, userId, changeDate, confirmDate, enroll, changeStatus, openReviewModal}) => {
    const isUserReceiver = message.receiverId == userId;
    const { width, height } = Dimensions.get('screen');
    
    return (
        <View style={{flexDirection: 'column'}}>
            {
                message.type == '1' ?
                <>
                    <View
                        style={{
                            alignSelf: isUserReceiver ? 'flex-start' : 'flex-end',
                            backgroundColor: isUserReceiver ? 'white' : '#2D81E0',
                            borderTopLeftRadius: 15,
                            borderTopRightRadius: 15,
                            borderBottomLeftRadius: isUserReceiver ? 5 : 15,
                            borderBottomRightRadius: !isUserReceiver ? 5 : 15,
                            flexDirection: 'row',
                            paddingHorizontal: 10,
                            padding: 7,
                            justifyContent: 'space-between',
                            borderColor: '#B5CADD',
                            borderWidth: isUserReceiver ? 1 : 0
                        }}>
                        <Text
                            style={{
                                color: isUserReceiver ? 'black' : 'white',
                                fontSize: 15,
                                fontWeight: '400',
                            }}>
                            {message.body}    
                        </Text>
                        <View
                            style={{flexDirection: 'column', justifyContent: 'flex-end', paddingLeft: 5}}>
                            <View
                                style={{flexDirection: 'row', alignSelf: 'flex-end'}}>
                                <Text
                                    style={{
                                        fontWeight: '100',
                                        fontSize: 11,
                                        alignSelf: 'flex-end',
                                        color: isUserReceiver ? 'black' : 'white',
                                        letterSpacing: 1
                                    }}>
                                    {dateHelper.getTimeFromString(message.creationTime)}
                                </Text>
                                {
                                    !isUserReceiver ? 
                                    <>
                                        <Icon
                                            type="material"
                                            name={message.isRead ? 'done-all' : 'check'}
                                            size={20}
                                            color={'white'}/>
                                    </>
                                    :
                                    <>
                                    </>
                                }    
                            </View>     
                        </View>
                    </View>
                </>
                :
                message.type == '2' ?
                <>
                    <View
                        style={{
                            alignSelf: isUserReceiver ? 'flex-start' : 'flex-end',
                            backgroundColor: isUserReceiver ? 'white' : '#2D81E0',
                            borderTopLeftRadius: 15,
                            borderTopRightRadius: 15,
                            borderBottomLeftRadius: isUserReceiver ? 5 : 15,
                            borderBottomRightRadius: !isUserReceiver ? 5 : 15,
                            maxWidth: width*0.9,
                            flexDirection: 'row',
                            paddingHorizontal: 10,
                            padding: 7,
                            justifyContent: 'space-between',
                            borderColor: '#B5CADD',
                            borderWidth: isUserReceiver ? 1 : 0
                        }}>
                        <View
                            style={{
                                flexDirection: 'row',
                            }}>
                            <Image
                                source={{uri: `${env.api_url}/api/objects/${message.body}`}}
                                style={{
                                    borderRadius: 15,
                                    width: 100,
                                    height: 100
                                }}/>
                            <Text
                                style={{
                                    alignSelf: 'center',
                                    fontWeight: '400',
                                    fontSize: 16,
                                    color: isUserReceiver ? '#2D81E0' : 'white',
                                    paddingLeft: 5
                                }}
                                numberOfLines={1}
                                lineBreakMode='head'>
                                {message.body.length > 20 ? message.body.slice(0, 19) : message.body}
                            </Text>    
                        </View>
                        <View
                            style={{flexDirection: 'column', justifyContent: 'flex-end', paddingLeft: 5}}>
                            <View
                                style={{flexDirection: 'row', alignSelf: 'flex-end'}}>
                                <Text
                                    style={{
                                        fontWeight: '100',
                                        fontSize: 11,
                                        alignSelf: 'flex-end',
                                        color: isUserReceiver ? 'black' : 'white',
                                        letterSpacing: 1
                                    }}>
                                    {dateHelper.getTimeFromString(message.creationTime)}
                                </Text>
                                {
                                    !isUserReceiver ? 
                                    <>
                                        <Icon
                                            type="material"
                                            name={message.isRead ? 'done-all' : 'check'}
                                            size={20}
                                            color={'white'}/>
                                    </>
                                    :
                                    <>
                                    </>
                                }    
                            </View>     
                        </View>
                    </View>
                </> 
                :
                <>
                    <View style={{paddingTop: 5}}>
                        <View
                            style={{
                                paddingHorizontal: 15,
                                borderRadius: 10,
                                backgroundColor: 'white',
                                borderColor: '#B5CADD',
                                borderWidth: 1
                            }}>
                            <Text
                                style={{
                                    color: 'black',
                                    fontSize: 14,
                                    fontWeight: '600',
                                    paddingTop: 10
                                }}>
                                {JSON.parse(message.body).UserChangedEnrollmentDate != null && JSON.parse(message.body).IsActive ? 
                                    (JSON.parse(message.body).UserChangedEnrollmentDate == userStore.get().guid ? 
                                        'Вы изменили дату и время записи' : userStore.getUserType() == 1 ? 
                                            'Компания предлагает изменить дату записи' : 
                                                'Клиент предлагает изменить дату записи ') : 
                                                    userStore.getUserType() == 1 ? 
                                                    'Ответ компании на ваш запрос' : 
                                                        'Ваш ответ на заказ клиента'}
                            </Text>
                            {
                                JSON.parse(message.body).Price > 0 ?
                                <>
                                    <View
                                        style={{
                                            flexDirection: 'row',
                                            justifyContent: 'space-between'
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
                                            justifyContent: 'space-between'
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
                                            justifyContent: 'space-between'
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
                                            {`${JSON.parse(message.body).IsActive ? dateHelper.formatDate(JSON.parse(message.body).EnrollmentTime) : dateHelper.formatDate(JSON.parse(message.body).PastEnrollmentTime)}`}        
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
                                            justifyContent: 'space-between'
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
                                            {`${JSON.parse(message.body).Prepayment}`}        
                                        </Text>
                                    </View>
                                </>
                                :
                                <>
                                </>
                            }
                            <View style={{paddingTop: 10, paddingBottom: 10}}>
                                {
                                    JSON.parse(message.body).Status != 1 ?
                                    <>
                                        <TouchableOpacity
                                            style={[
                                                styles.button, {
                                                    height: height/20                
                                                }
                                            ]}
                                            onPress={() => openReviewModal(message.id)}>
                                            <Text
                                                style={[
                                                    styles.buttonText, {
                                                        fontSize: 15
                                                    }
                                                ]}>
                                                Оставить отзыв    
                                            </Text>    
                                        </TouchableOpacity>    
                                    </>
                                    :
                                    <>
                                    </>
                                }
                                {
                                    JSON.parse(message.body).Status == 1 && JSON.parse(message.body).IsEnrolled ?
                                    <>
                                        <View style={{paddingBottom: 10}}>
                                            <View
                                                style={{
                                                    height: height/20,
                                                    borderRadius: 10,
                                                    backgroundColor: '#6DC876',
                                                    justifyContent: 'center',
                                                    flexDirection: 'row',
                                                    paddingHorizontal: 10
                                                }}>
                                                <View
                                                    style={{
                                                        alignSelf: 'center'
                                                    }}>
                                                    <Icon
                                                        type="materials"
                                                        name="celebration"
                                                        color='white'
                                                        size={20}/>
                                                </View>
                                                <Text
                                                    style={{
                                                        alignSelf: 'center',
                                                        fontSize: 15,
                                                        color: 'white',
                                                        fontWeight: '500',
                                                        paddingLeft: 5
                                                    }}>
                                                    {userStore.getUserType() == 2 ? (JSON.parse(message.body).EnrollmentTime != null ? `Клиент записан на ${dateHelper.formatDate(JSON.parse(message.body).EnrollmentTime)}` : 'Клиент записан') : (JSON.parse(message.body).EnrollmentTime != null ? `Вы записаны на ${dateHelper.formatDate(JSON.parse(message.body).EnrollmentTime)}` : 'Вы записаны')}
                                                </Text>
                                            </View>
                                            <View
                                                style={{
                                                    paddingTop: 5
                                                }}>
                                                <TouchableOpacity
                                                    style={[
                                                        styles.button, {
                                                            height: height/20
                                                        }
                                                    ]}
                                                    onPress={async () => await changeStatus(message.id, 2)}>
                                                    <Text
                                                        style={[
                                                            styles.buttonText, {
                                                                fontSize: 15
                                                            }
                                                        ]}>
                                                        Работа выполнена    
                                                    </Text>
                                                </TouchableOpacity>
                                            </View>
                                            <View
                                                style={{
                                                    paddingTop: 5
                                                }}>
                                                <TouchableOpacity
                                                    style={[
                                                        styles.button, {
                                                            height: height/20,
                                                            backgroundColor: '#001C3D0D'
                                                        }
                                                    ]}
                                                    onPress={async () => await changeStatus(message.id, 3)}>
                                                    <Text
                                                        style={[
                                                            styles.buttonText, {
                                                                fontSize: 15,
                                                                color: '#2688EB'
                                                            }
                                                        ]}>
                                                        Отменить запись    
                                                    </Text>
                                                </TouchableOpacity>
                                            </View>
                                        </View>
                                    </>
                                    :
                                    <>
                                    </>
                                }
                                {
                                    JSON.parse(message.body).Status == 1 && !JSON.parse(message.body).IsEnrolled && JSON.parse(message.body).IsActive && userStore.getUserType() == 2 && JSON.parse(message.body).UserChangedEnrollmentDate != null && JSON.parse(message.body).UserChangedEnrollmentDate != userStore.get().guid ?
                                    <>
                                        <View style={{paddingBottom: 5}}>
                                            <TouchableOpacity
                                                style={{
                                                    height: height/20,
                                                    borderRadius: 10,
                                                    backgroundColor: '#001C3D0D',
                                                    justifyContent: 'center'
                                                }}
                                                onPress={async () => await confirmDate(message.id)}>
                                                <Text
                                                    style={[
                                                        styles.buttonText, {
                                                            color: '#2688EB', 
                                                            fontSize: 15
                                                        }]}>
                                                    {`Подтвердить дату записи на ${dateHelper.getMonthAndDayFromString(JSON.parse(message.body).EnrollmentTime)} в ${dateHelper.getTimeFromString(JSON.parse(message.body).EnrollmentTime)}`}
                                                </Text>
                                            </TouchableOpacity>
                                        </View>
                                    </>
                                    :
                                    <>
                                    </>
                                }
                                {
                                    JSON.parse(message.body).Status == 1 && !JSON.parse(message.body).IsEnrolled ?
                                    <>
                                        <TouchableOpacity
                                            style={{
                                                height: height/20,
                                                borderRadius: 10,
                                                backgroundColor: JSON.parse(message.body).IsActive && (userStore.getUserType() == 1 ? JSON.parse(message.body).IsDateConfirmed : true) ? '#001C3D0D' : '#fafafb',
                                                justifyContent: 'center'
                                            }}
                                            disabled={!JSON.parse(message.body).IsActive || (userStore.getUserType() == 1 ? !JSON.parse(message.body).IsDateConfirmed : false)}
                                            onPress={JSON.parse(message.body).IsActive && (() => changeDate(JSON.parse(message.body).OrderId))}>
                                            <Text
                                                style={[
                                                    styles.buttonText, {
                                                        color: JSON.parse(message.body).IsActive && (userStore.getUserType() == 1 ? JSON.parse(message.body).IsDateConfirmed : true) ? '#2688EB' : '#a8cff7', 
                                                        fontSize: 15
                                                    }]}>
                                                {JSON.parse(message.body).UserChangedEnrollmentDate != null && JSON.parse(message.body).IsActive ? 'Предложить другую дату и время' : 'Изменить дату и время записи'}
                                            </Text>
                                        </TouchableOpacity>
                                    </>
                                    :
                                    <>
                                    </>
                                }
                                {
                                    JSON.parse(message.body).Status == 1 && userStore.getUserType() == 1 && JSON.parse(message.body).IsActive && JSON.parse(message.body).IsDateConfirmed && !JSON.parse(message.body).IsEnrolled ?
                                    <>
                                        <View style={{paddingTop: 10}}>
                                            <TouchableOpacity
                                                style={[
                                                    styles.button, {
                                                        height: height/20
                                                    }
                                                ]}
                                                onPress={() => enroll(message.id)}>
                                                <Text
                                                    style={[
                                                        styles.buttonText, {
                                                            fontSize: 15
                                                        }
                                                    ]}>
                                                    {JSON.parse(message.body).Prepayment > 0 ? 'Записаться и внести предоплату' : 'Записаться'}    
                                                </Text>
                                            </TouchableOpacity>
                                        </View>                                    
                                    </>
                                    :
                                    <>
                                    </>
                                }
                            </View>
                        </View>
                    </View>
                </>
            }    
        </View>
    )
}

export default Message;