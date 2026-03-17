import React from "react";
import {
    View,
    Text,
    Dimensions
} from 'react-native';
import { Icon } from "react-native-elements";
import userStore from "../services/userStore";

const Review = ({review}) => {
    const stars = [1,2,3,4,5];
    console.log(review);
    const wh = Dimensions.get('screen');
    const authorName = review?.author?.name || 'User_User';
    const shortName = (() => {
        if (userStore.getUserType() == 2) {
            return authorName;
        }

        const firstPart = authorName.split(' ')[0] || 'User';
        const surnamePart = authorName.includes('_') ? authorName.split('_')[1] : '';
        const initial = surnamePart ? surnamePart[0] : '';
        return initial ? `${firstPart} ${initial}.` : firstPart;
    })();

    return (
        <View
            style={{
                justifyContent: 'center',
                flexDirection: 'column'
            }}>
            <View
                style={{
                    flexDirection: 'row',
                    justifyContent: 'space-between'
                }}>
                <Text
                    style={{
                        fontWeight: '600',
                        fontSize: 16,
                        color: 'black'
                    }}>
                    {shortName}
                </Text>
                <View
                    style={{
                        flexDirection: 'row'
                    }}>
                    {stars.map(s => (
                        <Icon
                            type='material'
                            key={s}
                            name='star'
                            size={20}
                            color={s <= review.grade ? '#E4E839' : '#C8C8C8'}/>    
                        ))}
                </View>
            </View>
            <Text
                style={{
                    color: '#99A2AD',
                    fontSize: 14,
                    fontWeight: '400',
                    paddingTop: 10
                }}>
                {review.text}
            </Text>
            <View
                style={{
                    paddingTop: 10
                }}>
                <View
                    style={{
                        height: 5,
                        color: '#eaeaea',
                        width: wh.width
                    }}/>
            </View>
        </View>
    )
}

export default Review;
