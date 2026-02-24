import React from "react";
import {
    View,
    TouchableOpacity,
    Text
} from 'react-native';
import { Icon } from "react-native-elements";
import dateHelper from "../helpers/dateHelper";
import styles from "../Styles";

const OrderRequestCard = ({request, requestCategory, navigation }) => {
    const shortenDescription = 
        request.description.length > 60 ? 
        `${request.description.slice(0, 59)}...` : 
        request.description;

    return (
        <View
            style={{
                backgroundColor: 'white',
                borderRadius: 15,
                paddingHorizontal: 20,
                flexDirection: 'column',
                width: '90%',
                alignSelf: 'center',
                shadowColor: 'black',
                shadowOpacity: 0.1,
                shadowRadius: 100,
                elevation: 3,
                shadowOffset: {
                    width: 50,
                    height: 50
                }
            }}>
            <View
                style={{
                    borderRadius: 8,
                    backgroundColor: request.status == 1 ? '#6DC876' : request.status == 2 ? '#2D81E0' : '#AEAEB2',
                    padding: 5,
                    position: 'absolute',
                    right: 10,
                    top: 10
                }}>
                <Text 
                    style={{
                        fontWeight: '500',
                        fontSize: 14,
                        color: 'white',
                    }}>
                    {request.status == 1 ? 'Активен' : request.status == 2 ? 'Завершен' : 'Отменен'}
                </Text>
            </View>
            <View 
                style={{
                    paddingTop: 10
                }}>
                <Text
                    style={{
                        color: '#8E8E93',
                        fontWeight: '400',
                        fontSize: 13
                    }}>
                    {`№${request.id}`}
                </Text>
                <Text
                    style={{
                        color: 'black',
                        fontWeight: '600',
                        fontSize: 14
                    }}>
                    {requestCategory.title}
                </Text>
                <Text
                    style={{
                        fontSize: 15,
                        fontWeight: '400',
                        color: '#313131',
                        paddingTop: 10
                    }}>
                    {shortenDescription}    
                </Text>
                <View
                    style={{
                        flexDirection: 'row',
                        paddingTop: 10
                    }}>
                    <Icon 
                        name='calendar-month'
                        type='material'
                        color='#313131'
                        size={25}/>
                    <Text
                        style={{
                            color: '#313131',
                            fontSize: 15,
                            fontWeight: '500',
                            alignSelf: 'center'
                        }}>
                        {dateHelper.formatDate(request.creationDate)}
                    </Text>
                </View>
                <View style={{ paddingTop: 10, paddingBottom: 10 }}>
                    <TouchableOpacity 
                        style={[styles.button, { backgroundColor: '#001C3D0D' }]}
                        onPress={() => navigation.navigate('OrderRequest', { orderRequest: request })}>
                        <Text style={[styles.buttonText, { color: '#2688EB' }]}>
                            Подробнее
                        </Text>
                    </TouchableOpacity>
                </View>
            </View>
        </View>
    );
}

export default OrderRequestCard;