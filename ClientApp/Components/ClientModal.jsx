import React from "react"
import {
    View,
    TouchableOpacity,
    Text
} from 'react-native';
import { Icon } from "react-native-elements";
import ReviewPage from "./ReviewPage";

const ClientModal = ({client, close}) => {
    return (
        <View
            style={{
                flex: 1,
                justifyContent: 'center',
            }}>
            <View
                style={{
                    flexDirection: 'row',
                    justifyContent: 'space-between',
                    paddingTop: 10,
                    paddingHorizontal: 10
                }}>
                <Text></Text>
                <Text
                    style={{
                        color: 'black',
                        fontWeight: '600',
                        fontSize: 21
                    }}>
                    Отзывы
                </Text>
                <TouchableOpacity
                    onPress={() => close()}
                    style={{
                        borderRadius: 360,
                        backgroundColor: '#eff1f2',
                    }}>
                    <Icon 
                        name='close'
                        type='material'
                        size={27}
                        color='#818C99'/>
                </TouchableOpacity>    
            </View>
            <ReviewPage
                user={client}
                companyReviews={false}/>
        </View>
    )
}

export default ClientModal;