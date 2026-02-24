import React from "react";
import {
    View,
    Text,
    Image
} from 'react-native';
import { Icon } from "react-native-elements";
import { useIsFocused } from '@react-navigation/native';
import reviewService from "../services/reviewService";
import env from "../env";
import { FlatList } from "react-native-actions-sheet";
import Review from "./Review";

const ReviewPage = ({user, companyReviews}) => {
    const [reviews, setReviews] = React.useState([]);

    const isCompany = companyReviews == undefined ? true : companyReviews;

    const isFocused = useIsFocused();

    const retrieveData = React.useCallback(async () => {
        let reviews = await reviewService.get(user.guid);
        console.log(reviews);
        setReviews(reviews);
    }, []);

    React.useEffect(() => {
        isFocused && retrieveData();
    }, [isFocused]);

    return (
        <View
            style={{
                flex: 1,
                justifyContent: 'center'
            }}>
            <View
                style={{
                    flexDirection: 'row',
                    paddingTop: 10,
                    flex: 1,
                    paddingHorizontal: 10
                }}>
                <Image
                    source={{uri: `${env.api_url}/api/objects/${user.iconUri}`}}
                    style={{
                        width: 45,
                        height: 45,
                        borderRadius: 360,
                        resizeMode: 'contain',
                    }}/>
                <View
                    style={{
                        flexDirection: 'column',
                        justifyContent: 'space-evenly',
                        paddingLeft: 10,
                        flex: 1
                    }}>
                    <View
                        style={{
                            flexDirection: 'row',
                            justifyContent: 'space-between',
                            flex: 1,
                        }}>
                        <Text
                            style={{
                                color: 'black',
                                fontWeight: '600',
                                fontSize: 16
                            }}>
                            {isCompany ? user.title : `${user.surname} ${user.name}`}
                        </Text>
                        {isCompany ?
                        <>
                            <View
                                style={{
                                    flexDirection: 'row'
                                }}>
                                <Icon
                                    type='material'
                                    name='near-me'
                                    color='#99A2AD'
                                    size={20}/>
                                <Text
                                    style={{
                                        color: '#99A2AD',
                                        fontSize: 13,
                                        fontWeight: '400'
                                    }}>
                                    {`${user.distance} м от Вас`}
                                </Text>
                            </View> 
                        </>
                        :
                        <>
                        </>}   
                    </View>
                    <Text
                        style={{
                            color: '#99A2AD',
                            fontWeight: '400',
                            fontSize: 14
                        }}>
                        {`${user.address.city}, ${user.address.street}`}
                    </Text>
                </View>
            </View>
            <FlatList
                data={reviews}
                style={{
                    paddingTop: 20
                }}
                renderItem={({item}) => (
                    <View
                        style={{
                            paddingHorizontal: 10,
                            borderBottomWidth: 1,
                            borderColor: '#EAEAEA'
                        }}>
                        <Review
                            review={item}/>
                    </View>
                )}/>    
        </View>
    )
}

export default ReviewPage;