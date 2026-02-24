import React from 'react'
import {
    View,
    Text,
    Switch
} from 'react-native';

const Category = ({ category, selectCategory }) => {
    const onValueChanged = () => {
        category.track = !category.track;
        selectCategory({
            title: category.title,
            track: category.track,
            id: category.id
        });
    }

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
                {category.title}    
            </Text>
            <Switch
                trackColor={{true: '#2688EB', false: '#001C3D14'}} 
                thumbColor={'white'}
                value={category.track}
                disabled={category.track}
                onValueChange={onValueChanged}/>
        </View>
    );
}

export default Category;