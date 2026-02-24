import React from "react";
import {
    View,
    Image,
    Text,
    TouchableOpacity
} from 'react-native';
import env from "../env";
import { Icon } from "react-native-elements";
import clientService from "../services/clientService";

const Client = ({client, navigation}) => {
    return (
        <TouchableOpacity
            style={{
                flexDirection: 'row',
                justifyContent: 'space-between'
            }}
            onPress={async () => {
                let fetchedClient = await clientService.getAdmin(client.guid);

                navigation.navigate('EditClient', {client: fetchedClient});
            }}>
            <View
                style={{
                    flexDirection: 'row'
                }}>
                <Image
                    style={{
                        width: 45,
                        height: 45,
                        borderRadius: 360,
                    }}
                    source={{uri: `${env.api_url}/api/objects/${client.iconUri}`}}/>
                <View
                    style={{
                        flexDirection: 'column',
                        justifyContent: 'space-between',
                        paddingLeft: 10
                    }}>
                    <Text
                        style={{
                            fontSize: 16,
                            fontWeight: '600',
                            color: 'black'
                        }}>
                        {client.name}
                    </Text>
                    <Text
                        style={{
                            fontSize: 14,
                            fontWeight: '400',
                            color: '#99A2AD'
                        }}>
                        {`${client.city}, ${client.street}`}
                    </Text>    
                </View>    
            </View>
            <View
                style={{
                    alignSelf: 'center'
                }}>
                <Icon
                    type='material'
                    name='chevron-right'
                    color='#99A2AD'
                    size={30}/>
            </View>
        </TouchableOpacity>
    )
}

export default Client;