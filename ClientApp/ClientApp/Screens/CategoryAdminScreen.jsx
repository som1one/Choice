import React from 'react';
import {
    View,
    Text,
    FlatList,
    Image,
    TouchableOpacity,
    RefreshControl,
    Dimensions
} from 'react-native';
import { Icon } from 'react-native-elements';
import categoryStore from '../services/categoryStore.js';
import env from '../env.js';
import { useIsFocused } from '@react-navigation/native';
import styles from '../Styles.jsx';

export default function CategoryAdminScreen({ navigation, route }) {
    const [categories, setCategories] = React.useState(categoryStore.getCategories());
    const [refreshing, setRefreshing] = React.useState(false);

    const wh = Dimensions.get('screen');

    const isFocused = useIsFocused();

    const onRefresh = React.useCallback(async () => {
        setRefreshing(true);

        await categoryStore.retrieveData();
        setCategories(categoryStore.getCategories);

        setRefreshing(false);
    }, []);

    React.useEffect(() => {
        isFocused && onRefresh();
    }, [isFocused]);

    const onPressed = ({item}) => {
        navigation.navigate('EditCategory', {category: item});
    }

    return (
        <View style={{backgroundColor: 'white'}}>
            <FlatList 
                data={categories}
                refreshControl={
                    <RefreshControl refreshing={refreshing} onRefresh={onRefresh}/>
                }
                showsVerticalScrollIndicator
                style={{
                    maxHeight: wh.height*0.6
                }}
                renderItem={({item}) => {
                    return (
                        <View style={{paddingHorizontal: 10}}>
                            <TouchableOpacity onPress={() => onPressed({item})} style={{flex:1, flexDirection: 'row', justifyContent: 'flex-start', paddingHorizontal: 10, paddingVertical: 15, borderColor: '#e9e9e9', borderTopWidth: item.id == 1 ? 0 : 1}}>
                                <View style={{backgroundColor: '#47A4F9', borderRadius: 10, justifyContent: 'center', padding: 10}}>
                                    <Image 
                                        style={{height:20, width:20}}
                                        source={{uri: `${env.api_url}/api/objects/${item.iconUri}`}}/>
                                </View>
                                <Text style={{alignSelf: 'center', paddingLeft: 10, color: '#181818', fontWeight: '400', fontSize: 18}}>{item.title}</Text>
                                <View style={{flex: 1, flexDirection: 'row', alignSelf: 'center', justifyContent: 'flex-end'}}>
                                    <Icon 
                                        type='material'
                                        name='chevron-right'
                                        color={'#CDCECF'}/>
                                </View>
                            </TouchableOpacity>
                        </View>
                    );
                }}/>
            <View
                style={{
                    paddingHorizontal: 10
                }}>
                <TouchableOpacity
                    style={styles.button}
                    onPress={() => navigation.navigate('CreateCategory')}>
                    <Text
                        style={styles.buttonText}>
                        Добавить категорию
                    </Text>
                </TouchableOpacity>
            </View>
        </View>
    );
}