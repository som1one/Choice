import React from "react"
import {
    View,
    FlatList,
} from 'react-native';
import CompanyCategorySelectionComponent from "./CompanyCategorySelectionComponent";

const CompanyCategorySelectionList = ({categories}) => {
    
    return (
        <View
            style={{
                paddingTop: 20,
                paddingHorizontal: 10
            }}>
            <FlatList
                data={categories}
                renderItem={({item}) => {
                    return <View
                                style={{
                                    paddingTop: 10
                                }}>
                            <CompanyCategorySelectionComponent 
                                item={item}/>
                        </View>
                }}/>
        </View>
    )
}

export default CompanyCategorySelectionList;