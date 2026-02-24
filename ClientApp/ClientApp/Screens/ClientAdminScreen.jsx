import React from "react";
import  {
    View,
    FlatList,
    RefreshControl,
    Text,
    Dimensions,
    ScrollView
} from 'react-native';
import { Icon } from "react-native-elements";
import { useIsFocused } from '@react-navigation/native';
import Client from "../Components/Client";
import clientService from "../services/clientService";

const ClientAdminScreen = ({navigation}) => {
    const [refreshing, setRefreshing] = React.useState(false);
    const [clients, setClients] = React.useState([]);

    const retrieveData = React.useCallback(async () => {
        setRefreshing(true);

        let clients = await clientService.getAll();
        setClients(clients);

        setRefreshing(false);
    }, []);

    const isFocused = useIsFocused();

    React.useEffect(() => {
        isFocused && retrieveData();
    }, [isFocused]);

    return (
        <View
            style={{
                backgroundColor: 'white',
                flex: 1,
                paddingHorizontal: 15
            }}>
            {clients.length > 0 ?
            <>
                <FlatList
                    data={clients}
                    refreshControl={
                        <RefreshControl refreshing={refreshing} onRefresh={retrieveData}/>
                    }
                    renderItem={({item}) => {return (
                        <View
                            style={{paddingBottom: 5}}>
                            <Client
                                client={item}
                                navigation={navigation}/>
                        </View>
                    )}}/>
            </>
            :
            <>
                <ScrollView
                    refreshControl={
                        <RefreshControl refreshing={refreshing} onRefresh={retrieveData}/>
                    }>
                    <Icon 
                        size={60}
                        type='material'
                        name='sentiment-dissatisfied'
                        style={{paddingTop: 200}}
                        color='#3F8AE0'/>
                    <Text 
                        style={{
                            fontSize: 24, 
                            fontWeight: '700', 
                            color: 'black', 
                            alignSelf: 'center',
                            paddingTop: 30
                        }}>
                        Клиентов нет
                    </Text>
                    <Text 
                        style={{
                            fontSize: 16, 
                            fontWeight: '400', 
                            color: '#818C99', 
                            alignSelf: 'center',
                            paddingTop: 20
                        }}>
                        Дождитесь пока пользователи зарегистрируются
                    </Text>
                </ScrollView>
            </>}    
        </View>
    )
}

export default ClientAdminScreen;