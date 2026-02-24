import React from "react"
import {
    View,
    Text,
    TouchableOpacity,
    findNodeHandle,
    Animated,
    FlatList,
    Dimensions,
    KeyboardAvoidingView
} from 'react-native'
import { Icon } from "react-native-elements";
import { AuthContext } from "../App";
import CompanyAdminScreen from "./CompanyAdminScreen";
import ClientAdminScreen from "./ClientAdminScreen";
import CategoryAdminScreen from "./CategoryAdminScreen";
import Tabs from "../Components/Tabs";

const AdminScreen = ({navigation}) => {
    const { signOut } = React.useContext(AuthContext);
    const { width, height } = Dimensions.get('screen');

    const screens = {
        company: {
            screen: CompanyAdminScreen,
            title: 'Компании'
        },
        client: {
            screen: ClientAdminScreen,
            title: 'Клиенты'
        },
        category: {
            screen: CategoryAdminScreen,
            title: 'Категории'
        }
    };

    const data = Object.keys(screens).map((i) => ({
        key: i,
        screen: screens[i].screen,
        title: screens[i].title,
        ref: React.createRef()
    }));

    const scrollX = React.useRef(new Animated.Value(0)).current;
    const ref = React.useRef();
    const onItemPress = React.useCallback(itemIndex => {
        ref?.current?.scrollToOffset({
            offset: itemIndex * width
        });
    });

    return (
        <View
            style={{
                flex:1, 
                flexDirection: 'column',
                backgroundColor: 'white',
                width,
                position: 'absolute',
            }}>
            <View>
                <Text
                    style={{
                        alignSelf: 'center',
                        fontSize: 21,
                        fontWeight: '600',
                        color: 'black',
                        position: 'absolute',
                        top: 20,
                    }}>
                    Админ панель    
                </Text>
                <View
                    style={{
                        flexDirection: 'row',
                        justifyContent: 'flex-end',
                        paddingTop: 20,
                        paddingHorizontal: 15
                    }}>
                    <TouchableOpacity
                        onPress={async () => {
                            await signOut();
                        }}>
                        <Icon
                            name='logout'
                            type='material'
                            color='#2D81E0'
                            size={25}/>
                    </TouchableOpacity>
                </View>
                <View
                    style={{
                        paddingTop: 20,
                        flex: 1,
                        alignSelf: 'center'
                    }}>
                    <Tabs 
                        scrollX={scrollX} 
                        data={data} 
                        onItemPress={onItemPress}
                        admin/>
                </View>
            </View>
            <Animated.FlatList 
                data={data}
                ref={ref}
                keyExtractor={(item) => item.key}
                horizontal
                pagingEnabled
                style={{alignSelf: 'flex-end'}}
                bounces={false}
                onScroll={Animated.event(
                    [{nativeEvent: {contentOffset: {x: scrollX}}}],
                    { useNativeDriver: false }
                )}
                showsHorizontalScrollIndicator={false}
                renderItem={({item}) => {
                    return <View style={{width, height, paddingTop: 20}}>
                            <item.screen navigation={navigation}/>
                        </View>
                }}/>
        </View>
    )
}

export default AdminScreen;