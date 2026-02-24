import React from 'react';
import {
    View,
    FlatList,
    Text,
    RefreshControl,
    TouchableOpacity,
    ScrollView
} from 'react-native';
import clientService from '../services/clientService';
import OrderRequestCard from '../Components/OrderRequestCard';
import categoryStore from '../services/categoryStore';
import { Icon } from 'react-native-elements';
import styles from '../Styles';
import { useIsFocused } from '@react-navigation/native';
import authService from '../services/authService';

export default function OrderScreen({ navigation }) {
    const [orderRequests, setOrderRequests] = React.useState([]);
    const [refreshing, setRefreshing] = React.useState(false);

    const categories = categoryStore.getCategories();

    const isFocused = useIsFocused();

    const onRefresh = React.useCallback(async () => {
        setRefreshing(true);

        let requests = await clientService.getClientRequests();
        setOrderRequests(requests);

        setRefreshing(false);
    }, []);

    React.useEffect(() => {
        isFocused && onRefresh();
    }, [isFocused]);

    return (
        <View style={{flex: 1, backgroundColor: 'white'}}>
            <View style={{justifyContent: 'center', paddingTop: 20}}>
                <Text 
                    style={{
                        fontSize: 21, 
                        fontWeight: '600', 
                        color: 'black', 
                        alignSelf: 'center'
                    }}>
                    Заказы
                </Text>
            </View>
            {
                orderRequests.length == 0 ?
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
                            Давайте исправим это
                        </Text>
                        <View style={{paddingTop: 60, paddingHorizontal: 80}}>
                            <TouchableOpacity 
                                style={styles.button}
                                onPress={() => navigation.navigate('OrderRequestCreation', { category: categories[0] })}>
                                <Text style={styles.buttonText}>
                                    Создать заказ
                                </Text>
                            </TouchableOpacity>
                        </View>
                    </ScrollView>
                </>
                :
                <>
                    <FlatList
                        data={orderRequests}
                        style={{paddingTop: 20}}
                        showsVerticalScrollIndicator={false}
                        refreshControl={
                            <RefreshControl refreshing={refreshing} onRefresh={onRefresh}/>
                        }
                        renderItem={({item}) => {
                        return (
                            <View style={{width: '100%', paddingBottom: 10}}>
                                <OrderRequestCard 
                                    request={item} 
                                    requestCategory={categories[categories.findIndex(c => c.id == item.categoryId)]}
                                    navigation={navigation}/>
                            </View>
                        )
                        }}/>
                </>
            }
        </View>
    );
}