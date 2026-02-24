import React from "react";
import {
    View,
    Text,
    TouchableOpacity,
    ScrollView,
    FlatList,
    RefreshControl
} from 'react-native';
import clientService from "../services/clientService";
import userStore from "../services/userStore";
import CompanyRequestCard from "../Components/CompanyRequestCard";
import categoryStore from "../services/categoryStore";
import { useIsFocused } from '@react-navigation/native';
import { Icon } from "react-native-elements";
import styles from "../Styles";
import ClientModal from "../Components/ClientModal";
import { Modalize } from "react-native-modalize";

const CompanyRequestsScreen = ({navigation}) => {
    const [requests, setRequests] = React.useState([]);
    const [refreshing, setRefreshing] = React.useState(false);
    const [client, setClient] = React.useState();
    const modalRef = React.useRef(null);

    let user = userStore.get();

    const isFocused = useIsFocused();

    const onRefresh = React.useCallback(async () => {
        setRefreshing(true);

        let fetchedRequests = await clientService.getOrderRequest(user.categoriesId);
        await categoryStore.retrieveData();

        setRequests(fetchedRequests);

        setRefreshing(false);
    }, []);

    React.useEffect(() => {
        isFocused && onRefresh();
    }, [isFocused]);

    return (
        <View
            style={{
                flex: 1,
                backgroundColor: 'white'
            }}>
            <Modalize
                ref={modalRef}
                adjustToContentHeight={true}
                childrenStyle={{height: '100%'}}>
                <ClientModal
                    client={client}
                    close={() => modalRef.current.close()}/>
            </Modalize>
            <Text
                style={{
                    color: 'black',
                    fontSize: 21,
                    fontWeight: '600',
                    paddingTop: 20,
                    alignSelf: 'center'
                }}>
                Заказы    
            </Text>
            {
                requests.length > 0 ?
                <>
                    <FlatList
                        data={requests}
                        style={{
                            paddingTop: 20
                        }}
                        refreshControl={
                            <RefreshControl refreshing={refreshing} onRefresh={onRefresh}/>
                        }
                        renderItem={({item}) => {
                            return (
                                <View
                                    style={{paddingHorizontal: 10, paddingBottom: 10}}>
                                    <CompanyRequestCard 
                                        orderRequest={item}
                                        navigation={navigation}
                                        onPress={(client) => {
                                            setClient(client);
                                            modalRef.current?.open()
                                        }}
                                        button={true}/>
                                </View>
                            )
                        }}/>
                </>
                :
                <>
                    <ScrollView
                        refreshControl={
                            <RefreshControl refreshing={refreshing} onRefresh={onRefresh}/>
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
                            Пока нет заказов
                        </Text>
                        <Text 
                            style={{
                                fontSize: 16, 
                                fontWeight: '400', 
                                color: '#818C99', 
                                alignSelf: 'center',
                                paddingTop: 20
                            }}>
                            Дождитесь пока клиенты создадут заказ
                        </Text>
                    </ScrollView>        
                </>
            }    
        </View>
    );
}

export default CompanyRequestsScreen;