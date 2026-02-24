import React from "react";
import {
    View,
    Text,
    TouchableOpacity,
    DeviceEventEmitter
} from 'react-native';
import { Icon } from "react-native-elements";

const CompanyCategorySelectionComponent = ({item, countChanged}) => {
    const [tracked, setTracked] = React.useState(item.tracked);

    DeviceEventEmitter.addListener('addCategories', () => {
        item.tracked = tracked;
    });

    return (
        <View
            style={{
                flexDirection: 'row',
                justifyContent: 'space-between',
                paddingTop: 10
            }}>
            <Text
                style={{
                    fontSize: 17,
                    color: 'black',
                    fontWeight: '400'
                }}>
                {item.title}
            </Text>
            <TouchableOpacity
                style={{
                    width: 20, 
                    height: 20, 
                    backgroundColor: tracked ? '#2688EB' : '#E2E2E2', 
                    borderRadius: 360, 
                    justifyContent: 'center'
                }}
                onPress={() => {
                    setTracked(prev => !prev);
                    item.add(!tracked);
                }}>
                <Icon
                    name='done'
                    type='material'
                    color={'white'}
                    size={15}/>    
            </TouchableOpacity>
        </View>
    )
}

export default CompanyCategorySelectionComponent;